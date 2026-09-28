import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/animal_model.dart';
import '../models/dtos/notification_feed_snapshot.dart';
import '../models/enums/notification_type.dart';
import '../models/enums/user_role.dart';
import '../models/notification_model.dart';
import '../utils/animal_gender_words.dart';
import '../utils/reminder_config.dart';
import 'auth_service.dart';

// Gerencia a criação, leitura e marcação das notificações dos usuários no Firestore.
// Os métodos de criação nunca lançam erro, para que uma falha de notificação não interrompa o fluxo principal.
class NotificationService {
  // Instancia a referência para a coleção de notificações no banco de dados.
  final CollectionReference _notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');

  // Quantidade máxima de notificações carregadas na central.
  static const int _listLimit = 50;

  // Registra uma notificação para o usuário informado, registrando no console qualquer falha sem propagá-la.
  // Com documentId, reaproveita sempre o mesmo documento em vez de criar um novo.
  Future<void> create({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String relatedId = '',
    String? documentId,
  }) async {
    if (userId.isEmpty) return;

    try {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type.name,
        relatedId: relatedId,
        read: false,
        createdAt: DateTime.now(),
      );
      // Com id fixo, sobrescreve o documento existente (voltando a não lido e com data renovada).
      if (documentId != null) {
        await _notificationsCollection.doc(documentId).set(notification.toMap());
      } else {
        await _notificationsCollection.add(notification.toMap());
      }
    } catch (e) {
      debugPrint('Falha ao criar notificação (${type.name}): $e');
    }
  }

  // Recupera em tempo real as notificações mais recentes do usuário, da mais nova para a mais antiga.
  Stream<List<NotificationModel>> streamForUser(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(_listLimit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NotificationModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Recupera em tempo real as notificações mais recentes do usuário, indicando quais foram criadas
  // pelo próprio aparelho e ainda aguardam envio, e se a leitura veio do cache local.
  // Inclui as mudanças de metadados para saber quando o servidor confirmou a leitura, mesmo sem dados novos.
  Stream<NotificationFeedSnapshot> streamFeedForUser(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(_listLimit)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      final synced = <NotificationModel>[];
      final pendingIds = <String>{};

      for (final doc in snapshot.docs) {
        if (doc.metadata.hasPendingWrites) {
          pendingIds.add(doc.id);
        } else {
          synced.add(NotificationModel.fromMap(doc.id, doc.data() as Map<String, dynamic>));
        }
      }

      return NotificationFeedSnapshot(
        synced: synced,
        pendingIds: pendingIds,
        isFromCache: snapshot.metadata.isFromCache,
      );
    });
  }

  // Recupera em tempo real a quantidade de notificações ainda não lidas pelo usuário.
  Stream<int> streamUnreadCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Marca uma notificação específica como lida.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({'read': true});
    } catch (e) {
      debugPrint('Falha ao marcar notificação como lida: $e');
    }
  }

  // Marca todas as notificações não lidas do usuário como lidas em uma única operação.
  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Falha ao marcar todas as notificações como lidas: $e');
    }
  }

  // Dá boas-vindas ao usuário recém-cadastrado, com orientação adequada ao seu papel.
  Future<void> notifyWelcome({
    required String userId,
    required String role,
  }) {
    final body = role == UserRole.ngoRep.name
        ? 'Complete os dados da sua instituição para começar a publicar animais.'
        : 'Que bom ter você aqui! Conheça os animais que esperam por um lar.';
    return create(
      userId: userId,
      type: NotificationType.welcome,
      title: 'Boas-vindas ao Histórias de Resgate!',
      body: body,
    );
  }

  // Avisa o representante da ONG sobre uma nova solicitação de adoção recebida.
  Future<void> notifyAdoptionRequested({
    required String ngoOwnerId,
    required String ngoId,
    required String adopterName,
    required AnimalModel animal,
  }) {
    final words = AnimalGenderWords.fromGender(animal.gender);
    return create(
      userId: ngoOwnerId,
      type: NotificationType.adoptionRequested,
      relatedId: ngoId,
      title: 'Nova solicitação de adoção',
      body: '$adopterName quer adotar ${words.article} ${animal.name}.',
    );
  }

  // Confirma ao adotante que a solicitação de adoção foi enviada à ONG.
  Future<void> notifyAdoptionRequestSent({
    required String adopterId,
    required String ngoName,
    required AnimalModel animal,
  }) {
    final words = AnimalGenderWords.fromGender(animal.gender);
    return create(
      userId: adopterId,
      type: NotificationType.adoptionRequestSent,
      relatedId: animal.id,
      title: 'Solicitação enviada',
      body: 'A $ngoName recebeu seu interesse em ${words.article} ${animal.name} '
          'e vai entrar em contato pelo WhatsApp.',
    );
  }

  // Avisa o adotante que a ONG aprovou a solicitação de adoção.
  Future<void> notifyAdoptionApproved({
    required String adopterId,
    required String ngoName,
    required AnimalModel animal,
  }) {
    final words = AnimalGenderWords.fromGender(animal.gender);
    return create(
      userId: adopterId,
      type: NotificationType.adoptionApproved,
      relatedId: animal.id,
      title: 'Adoção aprovada!',
      body: 'Parabéns! Sua adoção ${words.contraction} ${animal.name} foi aprovada pela $ngoName.',
    );
  }

  // Avisa o adotante, em tom gentil, que a solicitação de adoção não foi aprovada.
  Future<void> notifyAdoptionRejected({
    required String adopterId,
    required AnimalModel animal,
  }) {
    final words = AnimalGenderWords.fromGender(animal.gender);
    return create(
      userId: adopterId,
      type: NotificationType.adoptionRejected,
      relatedId: animal.id,
      title: 'Sobre sua solicitação',
      body: 'Dessa vez a adoção ${words.contraction} ${animal.name} não foi possível, '
          'mas muitos outros animais esperam por um lar.',
    );
  }

  // Lembra o representante da ONG sobre solicitações de adoção sem resposta há vários dias.
  // Atualiza sempre o mesmo documento por usuário, para não acumular lembretes na central.
  Future<void> notifyPendingRequestsReminder({
    required String ngoOwnerId,
    required String ngoId,
    required int pendingCount,
  }) {
    return create(
      documentId: 'pendingRequestsReminder_$ngoOwnerId',
      userId: ngoOwnerId,
      type: NotificationType.pendingRequestsReminder,
      relatedId: ngoId,
      title: pendingRequestsReminderTitle,
      body: pendingRequestsReminderBody(pendingCount),
    );
  }

  // Título do lembrete de solicitações pendentes, compartilhado com a notificação do aparelho.
  static const String pendingRequestsReminderTitle = 'Solicitações aguardando resposta';

  // Monta o texto do lembrete de solicitações pendentes com a concordância da quantidade.
  static String pendingRequestsReminderBody(int pendingCount) {
    final requests = pendingCount == 1
        ? '1 solicitação de adoção espera'
        : '$pendingCount solicitações de adoção esperam';
    return '$requests sua resposta há mais de ${ReminderConfig.pendingRequestThresholdLabel}.';
  }

  // Avisa todos os administradores que uma instituição enviou os dados para análise.
  Future<void> notifyNgoSubmitted({
    required String ngoId,
    required String ngoName,
  }) async {
    try {
      final adminIds = await AuthService().getAdminIds();
      await Future.wait(adminIds.map((adminId) {
        return create(
          userId: adminId,
          type: NotificationType.ngoSubmitted,
          relatedId: ngoId,
          title: 'Nova instituição para análise',
          body: 'A $ngoName enviou os dados de cadastro e aguarda aprovação.',
        );
      }));
    } catch (e) {
      debugPrint('Falha ao notificar administradores sobre nova instituição: $e');
    }
  }

  // Avisa o representante que o cadastro da instituição foi aprovado.
  Future<void> notifyNgoApproved({
    required String representativeId,
    required String ngoId,
    required String ngoName,
  }) {
    return create(
      userId: representativeId,
      type: NotificationType.ngoApproved,
      relatedId: ngoId,
      title: 'Cadastro aprovado!',
      body: 'A $ngoName foi aprovada. Agora você já pode publicar animais para adoção.',
    );
  }

  // Avisa o representante, em tom gentil, que o cadastro da instituição não foi aprovado.
  Future<void> notifyNgoRejected({
    required String representativeId,
    required String ngoId,
    required String ngoName,
  }) {
    return create(
      userId: representativeId,
      type: NotificationType.ngoRejected,
      relatedId: ngoId,
      title: 'Sobre o cadastro da sua instituição',
      body: 'Não foi possível aprovar o cadastro da $ngoName desta vez. '
          'Confira se os dados estão corretos e entre em contato com a equipe do Histórias de Resgate.',
    );
  }
}
