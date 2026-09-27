import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../utils/notification_navigation.dart';
import '../utils/notification_permission.dart';
import '../widgets/info_banner.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/notification_tile.dart';

// Renderiza a central de notificações do usuário autenticado, com navegação para as telas relacionadas.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final LocalNotificationService _localNotificationService = LocalNotificationService();

  String? _userId;
  Stream<List<NotificationModel>>? _notificationsStream;

  // Indica se as notificações do aparelho estão ativas; começa como verdadeiro para não piscar o aviso.
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionStatus();
    _userId = _authService.currentUser?.uid;
    if (_userId != null) {
      _notificationsStream = _notificationService.streamForUser(_userId!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Confere a permissão de novo quando o usuário volta das configurações do Android.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermissionStatus();
  }

  // Atualiza o estado da permissão de notificações do aparelho.
  Future<void> _refreshPermissionStatus() async {
    final enabled = await _localNotificationService.areNotificationsEnabled();
    if (mounted && enabled != _notificationsEnabled) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  // Pede a permissão de novo ou abre as configurações do app quando o sistema bloqueia o pedido.
  Future<void> _handleEnableNotifications() async {
    await enableNotificationsOnRequest();
    await _refreshPermissionStatus();
  }

  // Constrói o aviso exibido enquanto as notificações do aparelho estiverem desativadas.
  Widget _buildPermissionBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: InfoBanner(
        type: InfoBannerType.warning,
        icon: Icons.notifications_off_outlined,
        message: 'Ative as notificações para ser avisado no celular',
        onTap: _handleEnableNotifications,
      ),
    );
  }

  // Marca a notificação como lida sem aguardar a rede e abre a tela relacionada ao seu tipo.
  Future<void> _handleTap(NotificationModel notification) async {
    if (!notification.read) {
      unawaited(_notificationService.markAsRead(notification.id));
    }

    await openNotificationTarget(
      navigator: Navigator.of(context),
      messenger: ScaffoldMessenger.of(context),
      type: notification.notificationType,
      relatedId: notification.relatedId,
    );
  }

  // Posiciona o aviso de permissão, quando necessário, acima do conteúdo da central.
  Widget _buildBody(Widget content) {
    if (_notificationsEnabled) return content;

    return Column(
      children: [
        _buildPermissionBanner(),
        Expanded(child: content),
      ],
    );
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
        body: _buildBody(_buildEmptyState()),
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
          body: _buildBody(body),
        );
      },
    );
  }
}
