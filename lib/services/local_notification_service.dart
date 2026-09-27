import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/enums/notification_type.dart';
import 'notification_service.dart';

// Reúne os dados levados por uma notificação do Android para abrir a tela correta ao tocar.
class LocalNotificationPayload {
  final NotificationType? type;
  final String relatedId;
  final String notificationId;

  // Inicializa o conteúdo da notificação com o tipo e os identificadores relacionados.
  const LocalNotificationPayload({
    required this.type,
    this.relatedId = '',
    this.notificationId = '',
  });

  // Converte o conteúdo em texto para ser guardado junto da notificação do Android.
  String encode() {
    return jsonEncode({
      'type': type?.name ?? '',
      'relatedId': relatedId,
      'notificationId': notificationId,
    });
  }

  // Recupera o conteúdo a partir do texto guardado, retornando null quando ausente ou inválido.
  static LocalNotificationPayload? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final typeName = data['type'] as String? ?? '';
      NotificationType? type;
      for (final value in NotificationType.values) {
        if (value.name == typeName) type = value;
      }
      return LocalNotificationPayload(
        type: type,
        relatedId: data['relatedId'] as String? ?? '',
        notificationId: data['notificationId'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('Conteúdo de notificação inválido: $e');
      return null;
    }
  }
}

// Gerencia as notificações do sistema Android: exibição, permissão, lembretes agendados e
// a escuta das notificações do Firestore enquanto o app está aberto ou em segundo plano.
// O estado fica em campos estáticos porque o plugin e a escuta são únicos no aplicativo.
// Os métodos nunca lançam erro, para que uma falha de notificação não interrompa o fluxo principal.
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static LocalNotificationPayload? _launchPayload;
  static void Function(LocalNotificationPayload payload)? _onTap;
  static StreamSubscription<dynamic>? _incomingSubscription;
  static String? _watchedUserId;

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'rescue_stories_default',
    'Histórias de Resgate',
    channelDescription: 'Avisos sobre adoções, instituições e lembretes do app.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _details = NotificationDetails(android: _androidDetails);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // Inicializa o plugin, registra a ação de toque e guarda a notificação que abriu o app, se houver.
  Future<void> initialize({required void Function(LocalNotificationPayload payload) onTap}) async {
    _onTap = onTap;
    if (_initialized || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = LocalNotificationPayload.decode(response.payload);
          if (payload != null) _onTap?.call(payload);
        },
      );
      _initialized = true;

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        _launchPayload = LocalNotificationPayload.decode(launchDetails!.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('Falha ao inicializar as notificações do aparelho: $e');
    }
  }

  // Retorna, uma única vez, a notificação tocada que abriu o aplicativo.
  LocalNotificationPayload? takeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  // Exibe uma notificação imediata no Android com o conteúdo informado.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required LocalNotificationPayload payload,
  }) async {
    if (!_initialized) return;

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
        payload: payload.encode(),
      );
    } catch (e) {
      debugPrint('Falha ao exibir notificação no aparelho: $e');
    }
  }

  // Agenda uma notificação repetida no intervalo informado, sem exigir alarme exato.
  Future<void> schedulePeriodic({
    required int id,
    required String title,
    required String body,
    required Duration interval,
    required LocalNotificationPayload payload,
  }) async {
    if (!_initialized) return;

    try {
      await _plugin.periodicallyShowWithDuration(
        id: id,
        title: title,
        body: body,
        repeatDurationInterval: interval,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload.encode(),
      );
    } catch (e) {
      debugPrint('Falha ao agendar lembrete no aparelho: $e');
    }
  }

  // Recupera os identificadores das notificações já agendadas no aparelho.
  Future<Set<int>> scheduledIds() async {
    if (!_initialized) return {};

    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((request) => request.id).toSet();
    } catch (e) {
      debugPrint('Falha ao consultar lembretes agendados: $e');
      return {};
    }
  }

  // Remove as notificações exibidas e os lembretes agendados (usado ao sair da conta).
  Future<void> cancelAll() async {
    if (!_initialized) return;

    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Falha ao cancelar as notificações do aparelho: $e');
    }
  }

  // Indica se o aplicativo pode exibir notificações no aparelho.
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) return false;

    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (e) {
      debugPrint('Falha ao consultar a permissão de notificações: $e');
      return false;
    }
  }

  // Solicita ao sistema a permissão de notificações e retorna se ela ficou concedida.
  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    try {
      await _android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Falha ao solicitar a permissão de notificações: $e');
    }
    return areNotificationsEnabled();
  }

  // Abre a tela de configurações de notificação do aplicativo no Android.
  Future<void> openNotificationSettings() async {
    if (!_initialized) return;

    try {
      await _android?.openAppNotificationSettings();
    } catch (e) {
      debugPrint('Falha ao abrir as configurações de notificação: $e');
    }
  }

  // Passa a exibir no Android as notificações novas do usuário que chegarem do servidor.
  void startWatching(String userId) {
    if (_watchedUserId == userId && _incomingSubscription != null) return;
    stopWatching();

    _watchedUserId = userId;
    _incomingSubscription = NotificationService().streamIncomingForUser(userId).listen(
      (notification) {
        show(
          id: notificationIdFor(notification.id),
          title: notification.title,
          body: notification.body,
          payload: LocalNotificationPayload(
            type: notification.notificationType,
            relatedId: notification.relatedId,
            notificationId: notification.id,
          ),
        );
      },
      onError: (Object e) => debugPrint('Falha na escuta de notificações: $e'),
    );
  }

  // Encerra a escuta das notificações do usuário.
  void stopWatching() {
    _incomingSubscription?.cancel();
    _incomingSubscription = null;
    _watchedUserId = null;
  }

  // Gera um identificador numérico estável (hash FNV-1a de 31 bits) para a notificação do Android.
  static int notificationIdFor(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}
