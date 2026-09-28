import '../notification_model.dart';

// Representa uma leitura das notificações do usuário, separando as já sincronizadas com o servidor
// das criadas pelo próprio aparelho que ainda aguardam envio.
class NotificationFeedSnapshot {
  final List<NotificationModel> synced;
  final Set<String> pendingIds;
  final bool isFromCache;

  // Inicializa a leitura com as notificações sincronizadas, os ids pendentes e a origem dos dados.
  NotificationFeedSnapshot({
    required this.synced,
    required this.pendingIds,
    required this.isFromCache,
  });
}
