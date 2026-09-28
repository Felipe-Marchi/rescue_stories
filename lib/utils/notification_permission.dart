import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_notification_service.dart';
import '../widgets/info_banner.dart';
import 'app_feedback.dart';

// Chave que registra se o pedido automático de permissão já foi feito neste aparelho.
const String _permissionAskedKey = 'notification_permission_asked';

// Explica o motivo e pede a permissão de notificações uma única vez por aparelho.
// Se o usuário tocar em "Agora não", o pedido do sistema não é feito; ele ainda pode ativar
// depois pelo aviso da central de notificações.
Future<void> askNotificationPermissionOnce(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final localNotificationService = LocalNotificationService();

  try {
    if (await localNotificationService.areNotificationsEnabled()) return;

    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_permissionAskedKey) ?? false) return;
    await preferences.setBool(_permissionAskedKey, true);

    if (!context.mounted) return;
    final accepted = await showFeedbackDialog(
      context,
      title: title,
      message: message,
      type: InfoBannerType.info,
      icon: Icons.notifications_active,
      confirmLabel: 'Ativar notificações',
      cancelLabel: 'Agora não',
    );

    if (accepted) await localNotificationService.requestPermission();
  } catch (e) {
    debugPrint('Falha ao pedir a permissão de notificações: $e');
  }
}

// Tenta ativar as notificações a pedido do usuário: pede a permissão de novo ou,
// se o sistema bloquear o pedido, abre as configurações de notificação do aplicativo.
Future<bool> enableNotificationsOnRequest() async {
  final localNotificationService = LocalNotificationService();

  // O diálogo do sistema deixa o app inativo; se isso não acontecer, o pedido foi bloqueado pelo Android.
  var systemDialogShown = false;
  final lifecycleListener = AppLifecycleListener(onInactive: () => systemDialogShown = true);

  final bool granted;
  try {
    granted = await localNotificationService.requestPermission();
  } finally {
    lifecycleListener.dispose();
  }
  if (granted) return true;

  if (!systemDialogShown) await localNotificationService.openNotificationSettings();
  return false;
}
