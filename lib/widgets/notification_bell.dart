import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/notifications_screen.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

// Renderiza o ícone de sino com o contador de notificações não lidas, visível apenas para usuários autenticados.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // Mantém o fluxo do contador por usuário para não recriar a consulta a cada reconstrução da tela.
  String? _currentUserId;
  Stream<int>? _unreadCountStream;

  // Retorna o fluxo do contador do usuário informado, recriando-o apenas quando o usuário muda.
  Stream<int> _unreadCountFor(String userId) {
    if (_currentUserId != userId || _unreadCountStream == null) {
      _currentUserId = userId;
      _unreadCountStream = _notificationService.streamUnreadCount(userId);
    }
    return _unreadCountStream!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<int>(
          stream: _unreadCountFor(user.uid),
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? 0;

            return IconButton(
              tooltip: 'Notificações',
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text(count > 9 ? '9+' : '$count'),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.green,
                  size: 30.0,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
