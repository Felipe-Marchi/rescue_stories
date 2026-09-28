import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_model.dart';
import '../models/enums/notification_type.dart';
import '../models/user_model.dart';
import '../utils/animal_gender_words.dart';
import '../utils/reminder_config.dart';
import 'adoption_service.dart';
import 'animal_service.dart';
import 'local_notification_service.dart';
import 'notification_service.dart';

// Gerencia os lembretes periódicos: solicitações pendentes da ONG e acompanhamento do animal adotado.
// É executado ao abrir o app e ao voltar para ele, e nunca lança erro.
class ReminderService {
  final AdoptionService _adoptionService = AdoptionService();
  final AnimalService _animalService = AnimalService();
  final NotificationService _notificationService = NotificationService();
  final LocalNotificationService _localNotificationService = LocalNotificationService();

  // Evita verificações simultâneas (abertura do app e retorno ao primeiro plano ao mesmo tempo).
  static bool _isChecking = false;

  // Verifica e dispara ou agenda os lembretes adequados ao papel do usuário.
  Future<void> checkForUser(UserModel user) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      if (user.isNgoRep && user.isActive && (user.ngoId ?? '').isNotEmpty) {
        await _checkPendingRequests(user);
      } else if (user.isAdopter) {
        await _scheduleAdoptionFollowUps(user);
      }
    } catch (e) {
      debugPrint('Falha ao verificar os lembretes: $e');
    } finally {
      _isChecking = false;
    }
  }

  // Registra que a ONG abriu "Solicitações de Adoção", adiando o lembrete de pendentes.
  Future<void> recordAdoptionRequestsVisit(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(_lastVisitKey(userId), DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Falha ao registrar a visita às solicitações de adoção: $e');
    }
  }

  // Lembra a ONG sobre solicitações pendentes além do prazo, respeitando o intervalo entre lembretes
  // e sem lembrar quem abriu as solicitações recentemente.
  Future<void> _checkPendingRequests(UserModel user) async {
    final ngoId = user.ngoId!;
    final preferences = await SharedPreferences.getInstance();
    final lastReminderKey = 'ngo_reminder_last_${user.id}';

    if (_isWithin(preferences.getInt(lastReminderKey), ReminderConfig.ngoReminderInterval)) return;
    if (_isWithin(preferences.getInt(_lastVisitKey(user.id)), ReminderConfig.recentVisitWindow)) return;

    final pendingCount = await _adoptionService.countPendingOlderThan(
      ngoId,
      ReminderConfig.pendingRequestThreshold,
    );
    if (pendingCount == 0) return;

    await preferences.setInt(lastReminderKey, DateTime.now().millisecondsSinceEpoch);

    // Registra na central e exibe no aparelho, já que a escuta ignora notificações criadas localmente.
    await _notificationService.notifyPendingRequestsReminder(
      ngoOwnerId: user.id,
      ngoId: ngoId,
      pendingCount: pendingCount,
    );
    await _localNotificationService.show(
      id: LocalNotificationService.notificationIdFor('pendingRequestsReminder:$ngoId'),
      title: NotificationService.pendingRequestsReminderTitle,
      body: NotificationService.pendingRequestsReminderBody(pendingCount),
      payload: LocalNotificationPayload(
        type: NotificationType.pendingRequestsReminder,
        relatedId: ngoId,
      ),
    );
  }

  // Reagenda o lembrete de acompanhamento do adotante a partir de agora, sem as demais verificações.
  // Usado quando o app vai para segundo plano, para contar a inatividade a partir da saída.
  Future<void> rescheduleAdoptionFollowUp(UserModel user) async {
    if (!user.isAdopter || _isChecking) return;
    _isChecking = true;

    try {
      await _scheduleAdoptionFollowUps(user);
    } catch (e) {
      debugPrint('Falha ao reagendar o lembrete de acompanhamento: $e');
    } finally {
      _isChecking = false;
    }
  }

  // Agenda os lembretes de inatividade do adotante: cancela todos os de acompanhamento e, se houver
  // adoção aprovada, agenda dois alarmes únicos, após 1 e 2 períodos de inatividade contados de agora.
  // Como roda a cada uso do app, o prazo é sempre empurrado para frente.
  Future<void> _scheduleAdoptionFollowUps(UserModel user) async {
    // Cancela todos os lembretes de acompanhamento, inclusive os de versões anteriores do app.
    final scheduled = await _localNotificationService.scheduledReminders();
    final existingIds = scheduled.entries
        .where((entry) => entry.value?.type == NotificationType.adoptionFollowUpReminder)
        .map((entry) => entry.key)
        .toList();
    for (final id in existingIds) {
      await _localNotificationService.cancel(id);
    }

    final approvedRequests = await _adoptionService.getApprovedRequestsByAdopter(user.id);

    // Agrupa por animal, guardando a decisão mais recente de cada um
    // (solicitações antigas, sem data de decisão, usam a data de criação).
    final decidedAtByAnimal = <String, DateTime>{};
    for (final request in approvedRequests) {
      final decidedAt = request.decidedAt ?? request.createdAt;
      final current = decidedAtByAnimal[request.animalId];
      if (current == null || decidedAt.isAfter(current)) {
        decidedAtByAnimal[request.animalId] = decidedAt;
      }
    }

    // Ordena da adoção mais recente para a mais antiga e ignora animais que não existem mais.
    final animalIds = decidedAtByAnimal.keys.toList()
      ..sort((a, b) => decidedAtByAnimal[b]!.compareTo(decidedAtByAnimal[a]!));
    final animals = <AnimalModel>[];
    for (final animalId in animalIds) {
      final animal = await _animalService.getAnimalById(animalId);
      if (animal != null) animals.add(animal);
    }

    if (animals.isEmpty) return;

    // O primeiro lembrete respeita o prazo mínimo após a aprovação mais recente; o segundo vem um período depois.
    final now = DateTime.now();
    final period = ReminderConfig.adoptionInactivityPeriod;
    final earliest = decidedAtByAnimal[animals.first.id]!.add(ReminderConfig.adoptionFollowUpMinDelay);
    final first = _outsideQuietHours(_latest(now.add(period), earliest));
    final second = _outsideQuietHours(_latest(now.add(period * 2), first.add(period)));

    final texts = _followUpTexts(animals);
    final payload = LocalNotificationPayload(
      type: NotificationType.adoptionFollowUpReminder,
      // Com um animal, o toque abre o detalhe dele; com vários, abre a Home.
      relatedId: animals.length == 1 ? animals.first.id : '',
    );

    final occurrences = [first, second];
    for (var index = 0; index < occurrences.length; index++) {
      await _localNotificationService.scheduleAt(
        id: LocalNotificationService.notificationIdFor('adoptionFollowUp:${user.id}:${index + 1}'),
        title: texts.title,
        body: texts.body,
        when: occurrences[index],
        payload: payload,
      );
    }
  }

  // Retorna o mais tardio entre dois instantes.
  DateTime _latest(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

  // Move o instante para as 10h quando cai no horário de silêncio: do mesmo dia, se for de madrugada,
  // ou do dia seguinte, se for à noite. Usa o horário local do aparelho.
  DateTime _outsideQuietHours(DateTime moment) {
    if (!ReminderConfig.applyQuietHours) return moment;

    final local = moment.toLocal();
    if (local.hour >= ReminderConfig.quietHoursEnd && local.hour < ReminderConfig.quietHoursStart) {
      return moment;
    }

    final day = local.hour < ReminderConfig.quietHoursEnd ? local.day : local.day + 1;
    return DateTime(local.year, local.month, day, ReminderConfig.quietHoursRescheduleHour);
  }

  // Monta o título e o texto do lembrete de acompanhamento, com a concordância pelo sexo e pela quantidade.
  ({String title, String body}) _followUpTexts(List<AnimalModel> animals) {
    final names = animals.map((animal) {
      return '${AnimalGenderWords.fromGender(animal.gender).article} ${animal.name}';
    }).toList();

    if (animals.length == 1) {
      final words = AnimalGenderWords.fromGender(animals.first.gender);
      return (
        title: 'Como está ${names.first}?',
        body: 'Conte para a ONG como ${words.subject} está se adaptando ao novo lar.',
      );
    }

    final title = animals.length == 2
        ? 'Como estão ${names[0]} e ${names[1]}?'
        : 'Como estão ${names[0]}, ${names[1]} e mais ${animals.length - 2}?';
    final allFemale = animals.every((animal) => animal.gender == 'Fêmea');
    final subject = allFemale ? 'elas' : 'eles';

    return (
      title: title,
      body: 'Conte para a ONG como $subject estão se adaptando ao novo lar.',
    );
  }

  // Indica se o instante gravado (em milissegundos) está dentro do período informado até agora.
  bool _isWithin(int? millis, Duration period) {
    if (millis == null) return false;
    final moment = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime.now().difference(moment) < period;
  }

  static String _lastVisitKey(String userId) => 'adoption_requests_opened_$userId';
}
