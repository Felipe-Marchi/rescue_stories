import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Lembra a ONG sobre solicitações pendentes além do prazo, no máximo uma vez por intervalo configurado.
  Future<void> _checkPendingRequests(UserModel user) async {
    final ngoId = user.ngoId!;
    final preferences = await SharedPreferences.getInstance();
    final lastReminderKey = 'ngo_reminder_last_${user.id}';

    final lastReminderMillis = preferences.getInt(lastReminderKey);
    if (lastReminderMillis != null) {
      final lastReminder = DateTime.fromMillisecondsSinceEpoch(lastReminderMillis);
      if (DateTime.now().difference(lastReminder) < ReminderConfig.ngoReminderInterval) return;
    }

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

  // Agenda o lembrete periódico de cada adoção aprovada, sem reagendar os que já estão agendados.
  Future<void> _scheduleAdoptionFollowUps(UserModel user) async {
    final approvedRequests = await _adoptionService.getApprovedRequestsByAdopter(user.id);
    if (approvedRequests.isEmpty) return;

    final scheduledIds = await _localNotificationService.scheduledIds();

    for (final request in approvedRequests) {
      final reminderId = LocalNotificationService.notificationIdFor('adoptionFollowUp:${request.id}');
      if (scheduledIds.contains(reminderId)) continue;

      final animal = await _animalService.getAnimalById(request.animalId);
      if (animal == null) continue;

      final words = AnimalGenderWords.fromGender(animal.gender);
      await _localNotificationService.schedulePeriodic(
        id: reminderId,
        title: 'Como está ${words.article} ${animal.name}?',
        body: 'Conte para a ONG como ${words.subject} está se adaptando ao novo lar.',
        interval: ReminderConfig.adoptionFollowUpInterval,
        payload: LocalNotificationPayload(
          type: NotificationType.adoptionFollowUpReminder,
          relatedId: animal.id,
        ),
      );
    }
  }
}
