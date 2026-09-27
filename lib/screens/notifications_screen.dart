import 'dart:async';
import 'package:flutter/material.dart';
import '../models/enums/notification_type.dart';
import '../models/notification_model.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/notification_tile.dart';
import '../utils/app_feedback.dart';
import '../widgets/info_banner.dart';
import 'adoption_management_screen.dart';
import 'animal_detail_screen.dart';
import 'ngo_management_screen.dart';
import 'profile_screen.dart';

// Renderiza a central de notificações do usuário autenticado, com navegação para as telas relacionadas.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final AnimalService _animalService = AnimalService();

  String? _userId;
  Stream<List<NotificationModel>>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    _userId = _authService.currentUser?.uid;
    if (_userId != null) {
      _notificationsStream = _notificationService.streamForUser(_userId!);
    }
  }

  // Marca a notificação como lida sem aguardar a rede e abre a tela relacionada ao seu tipo.
  Future<void> _handleTap(NotificationModel notification) async {
    if (!notification.read) {
      unawaited(_notificationService.markAsRead(notification.id));
    }

    final relatedId = notification.relatedId;

    switch (notification.notificationType) {
      case NotificationType.adoptionRequested:
      case NotificationType.pendingRequestsReminder:
        if (relatedId.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdoptionManagementScreen(ngoId: relatedId),
          ),
        );
        break;

      case NotificationType.adoptionRequestSent:
      case NotificationType.adoptionApproved:
      case NotificationType.adoptionRejected:
      case NotificationType.adoptionFollowUpReminder:
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        final animal = await _animalService.getAnimalById(relatedId);

        if (animal == null) {
          messenger.showSnackBar(buildAppSnackBar('Este animal não está mais disponível.', type: InfoBannerType.info));
          return;
        }

        navigator.push(
          MaterialPageRoute(
            builder: (context) => AnimalDetailScreen(animal: animal),
          ),
        );
        break;

      case NotificationType.ngoSubmitted:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NgoManagementScreen(),
          ),
        );
        break;

      case NotificationType.ngoApproved:
      case NotificationType.ngoRejected:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
        break;

      case null:
        break;
    }
  }

  // Constrói o estado vazio amigável exibido quando não há notificações.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 72.0,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Nenhuma notificação por aqui',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Avisaremos quando houver novidades sobre adoções.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationsStream == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: const CustomAppBar(title: 'Notificações'),
        body: _buildEmptyState(),
      );
    }

    return StreamBuilder<List<NotificationModel>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final hasUnread = notifications.any((notification) => !notification.read);

        Widget body;
        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          body = const Center(child: Text('Erro ao carregar as notificações.'));
        } else if (notifications.isEmpty) {
          body = _buildEmptyState();
        } else {
          body = ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(
                notification: notification,
                onTap: () => _handleTap(notification),
              );
            },
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: CustomAppBar(
            title: 'Notificações',
            actions: [
              if (hasUnread)
                TextButton(
                  onPressed: () => _notificationService.markAllAsRead(_userId!),
                  child: Text(
                    'Marcar todas como lidas',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8.0),
            ],
          ),
          body: body,
        );
      },
    );
  }
}
