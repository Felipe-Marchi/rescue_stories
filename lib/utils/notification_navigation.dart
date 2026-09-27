import 'dart:async';
import 'package:flutter/material.dart';
import '../models/enums/notification_type.dart';
import '../screens/adoption_management_screen.dart';
import '../screens/animal_detail_screen.dart';
import '../screens/ngo_management_screen.dart';
import '../screens/profile_screen.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../widgets/info_banner.dart';
import 'app_feedback.dart';

// Chaves globais do MaterialApp, usadas para navegar a partir do toque em uma notificação do Android.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Abre a tela relacionada ao tipo da notificação; usada pela central e pelas notificações do Android.
Future<void> openNotificationTarget({
  required NavigatorState navigator,
  required ScaffoldMessengerState? messenger,
  required NotificationType? type,
  required String relatedId,
}) async {
  switch (type) {
    case NotificationType.adoptionRequested:
    case NotificationType.pendingRequestsReminder:
      if (relatedId.isEmpty) return;
      navigator.push(
        MaterialPageRoute(
          builder: (context) => AdoptionManagementScreen(ngoId: relatedId),
        ),
      );
      break;

    case NotificationType.adoptionRequestSent:
    case NotificationType.adoptionApproved:
    case NotificationType.adoptionRejected:
    case NotificationType.adoptionFollowUpReminder:
      final animal = await AnimalService().getAnimalById(relatedId);

      if (animal == null) {
        messenger?.showSnackBar(buildAppSnackBar('Este animal não está mais disponível.', type: InfoBannerType.info));
        return;
      }

      navigator.push(
        MaterialPageRoute(
          builder: (context) => AnimalDetailScreen(animal: animal),
        ),
      );
      break;

    case NotificationType.ngoSubmitted:
      navigator.push(
        MaterialPageRoute(
          builder: (context) => NgoManagementScreen(),
        ),
      );
      break;

    case NotificationType.ngoApproved:
    case NotificationType.ngoRejected:
      navigator.push(
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
      break;

    case null:
      break;
  }
}

// Abre a tela da notificação do Android tocada pelo usuário e a marca como lida na central.
Future<void> openLocalNotification(LocalNotificationPayload payload) async {
  if (AuthService().currentUser == null) return;

  if (payload.notificationId.isNotEmpty) {
    unawaited(NotificationService().markAsRead(payload.notificationId));
  }

  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  await openNotificationTarget(
    navigator: navigator,
    messenger: appScaffoldMessengerKey.currentState,
    type: payload.type,
    relatedId: payload.relatedId,
  );
}
