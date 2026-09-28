import 'package:flutter/material.dart';
import '../models/enums/notification_type.dart';
import '../models/notification_model.dart';
import '../utils/formatters.dart';
import 'info_banner.dart';

// Renderiza um item da central de notificações com ícone e cores do tipo, destacando as não lidas.
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  // Inicializa o componente exigindo a notificação e aceitando a ação ao tocar.
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  // Associa cada tipo de notificação a uma variação visual do InfoBanner.
  InfoBannerType get _bannerType {
    switch (notification.notificationType) {
      case NotificationType.adoptionApproved:
      case NotificationType.ngoApproved:
      case NotificationType.welcome:
        return InfoBannerType.success;
      case NotificationType.adoptionRequested:
      case NotificationType.ngoSubmitted:
      case NotificationType.pendingRequestsReminder:
        return InfoBannerType.warning;
      case NotificationType.ngoRejected:
        return InfoBannerType.error;
      case NotificationType.adoptionRequestSent:
      case NotificationType.adoptionRejected:
      case NotificationType.adoptionFollowUpReminder:
      case null:
        return InfoBannerType.info;
    }
  }

  // Associa cada tipo de notificação a um ícone representativo.
  IconData get _icon {
    switch (notification.notificationType) {
      case NotificationType.adoptionRequested:
        return Icons.volunteer_activism;
      case NotificationType.adoptionRequestSent:
        return Icons.send;
      case NotificationType.adoptionApproved:
        return Icons.celebration;
      case NotificationType.adoptionRejected:
        return Icons.favorite_border;
      case NotificationType.ngoApproved:
        return Icons.verified;
      case NotificationType.ngoRejected:
        return Icons.business;
      case NotificationType.ngoSubmitted:
        return Icons.assignment_outlined;
      case NotificationType.pendingRequestsReminder:
        return Icons.schedule;
      case NotificationType.adoptionFollowUpReminder:
        return Icons.pets;
      case NotificationType.welcome:
        return Icons.waving_hand;
      case null:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = InfoBannerStyle.of(_bannerType);
    final isUnread = !notification.read;
    final borderRadius = BorderRadius.circular(12.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        // Não lidas ganham um fundo verde bem claro; lidas ficam brancas.
        color: isUnread ? Colors.green.shade50.withValues(alpha: 0.5) : Colors.white,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: isUnread ? Colors.green.shade100 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exibe o ícone do tipo dentro de um círculo com a cor clara correspondente.
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: style.backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: style.accentColor, size: 20.0),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: isUnread ? Colors.black87 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            formatRelativeDate(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11.0,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          // Exibe um ponto verde indicador nas notificações ainda não lidas.
                          if (isUnread) ...[
                            const SizedBox(width: 6.0),
                            Container(
                              width: 8.0,
                              height: 8.0,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.0,
                          height: 1.3,
                          color: isUnread ? Colors.grey.shade800 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
