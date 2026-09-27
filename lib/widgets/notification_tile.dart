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
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        color: isUnread ? style.backgroundColor : Colors.white,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: isUnread ? style.borderColor : Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon, color: style.accentColor, size: 26.0),
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
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            formatRelativeDate(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14.0,
                          height: 1.3,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Exibe um ponto indicador nas notificações ainda não lidas.
                if (isUnread) ...[
                  const SizedBox(width: 8.0),
                  Container(
                    margin: const EdgeInsets.only(top: 6.0),
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: style.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
