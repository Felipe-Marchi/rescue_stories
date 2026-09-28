import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/dtos/notification_feed_snapshot.dart';
import '../models/enums/notification_type.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

// Reúne os dados levados por uma notificação do Android para abrir a tela correta ao tocar.
class LocalNotificationPayload {
  final NotificationType? type;
  final String relatedId;
  final String notificationId;
  final bool opensCentral;

  // Inicializa o conteúdo da notificação com o tipo e os identificadores relacionados.
  // Com opensCentral, o toque abre a central de notificações (usado no resumo de novidades).
  const LocalNotificationPayload({
    required this.type,
    this.relatedId = '',
    this.notificationId = '',
    this.opensCentral = false,
  });

  // Converte o conteúdo em texto para ser guardado junto da notificação do Android.
  String encode() {
    return jsonEncode({
      'type': type?.name ?? '',
      'relatedId': relatedId,
      'notificationId': notificationId,
      'opensCentral': opensCentral,
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
        opensCentral: data['opensCentral'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('Conteúdo de notificação inválido: $e');
      return null;
    }
  }
}

// Guarda o estado da escuta de um usuário: a data de corte da sessão e as notificações já tratadas.
class _WatchSession {
  final DateTime threshold;
  final List<String> seenKeys;

  _WatchSession({required this.threshold, required this.seenKeys});
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

  static StreamSubscription<NotificationFeedSnapshot>? _feedSubscription;
  static String? _watchedUserId;
  static Future<_WatchSession>? _session;
  static Future<void> _processing = Future.value();
  static final Set<String> _selfCreatedIds = {};

  // Acima dessa quantidade de novidades, exibe um resumo em vez de uma notificação para cada.
  static const int _maxIndividualNotifications = 3;

  // Quantidade de notificações já tratadas lembradas por usuário, para nunca repetir a mesma.
  static const int _maxSeenKeys = 100;

  // Na primeira vez em um aparelho, considera apenas as novidades desse período.
  static const Duration _firstRunWindow = Duration(hours: 24);

  // Tolera pequenas diferenças entre o relógio do aparelho e o do servidor.
  static const Duration _clockMargin = Duration(minutes: 1);

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'rescue_stories_default',
    'Histórias de Resgate',
    channelDescription: 'Avisos sobre adoções, instituições e lembretes do app.',
    importance: Importance.high,
    priority: Priority.high,
    // Cor de destaque do app (Colors.green) aplicada ao ícone da pata.
    color: Color(0xFF4CAF50),
  );

  static const NotificationDetails _details = NotificationDetails(android: _androidDetails);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // Inicializa os fusos horários e o plugin, registra a ação de toque e guarda a notificação que abriu o app.
  Future<void> initialize({required void Function(LocalNotificationPayload payload) onTap}) async {
    _onTap = onTap;
    if (_initialized || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      // Os lembretes são agendados em instantes absolutos (UTC), então basta carregar a base de fusos.
      tz_data.initializeTimeZones();

      await _plugin.initialize(
        settings: const InitializationSettings(
          // Ícone monocromático de pata exibido na barra de status.
          android: AndroidInitializationSettings('@drawable/ic_stat_notification'),
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

  // Usa alarme exato em modo debug, quando liberado, para que os lembretes de teste disparem no horário;
  // fora disso, usa alarme inexato, que não exige permissão especial.
  Future<AndroidScheduleMode> _reminderScheduleMode() async {
    if (!kDebugMode) return AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      if (await _android?.canScheduleExactNotifications() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('Falha ao consultar a permissão de alarme exato: $e');
    }
    debugPrint('Alarme exato não liberado; o lembrete de teste usará alarme inexato.');
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  // Agenda uma notificação única para o instante informado.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required LocalNotificationPayload payload,
  }) async {
    if (!_initialized) return;

    try {
      final scheduleMode = await _reminderScheduleMode();
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.UTC),
        notificationDetails: _details,
        androidScheduleMode: scheduleMode,
        payload: payload.encode(),
      );
    } catch (e) {
      debugPrint('Falha ao agendar lembrete no aparelho: $e');
    }
  }

  // Recupera os lembretes agendados no aparelho, com o conteúdo de cada um (pelo identificador).
  Future<Map<int, LocalNotificationPayload?>> scheduledReminders() async {
    if (!_initialized) return {};

    try {
      final pending = await _plugin.pendingNotificationRequests();
      return {
        for (final request in pending) request.id: LocalNotificationPayload.decode(request.payload),
      };
    } catch (e) {
      debugPrint('Falha ao consultar lembretes agendados: $e');
      return {};
    }
  }

  // Cancela a notificação ou o lembrete agendado com o identificador informado.
  Future<void> cancel(int id) async {
    if (!_initialized) return;

    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Falha ao cancelar notificação do aparelho: $e');
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

  // Passa a exibir no Android as notificações não lidas do usuário: primeiro as que chegaram
  // desde a última sincronização deste aparelho e, depois, as novas que chegarem do servidor.
  void startWatching(String userId) {
    if (_watchedUserId == userId && _feedSubscription != null) return;
    stopWatching();

    _watchedUserId = userId;
    _session = _loadSession(userId);
    _feedSubscription = NotificationService().streamFeedForUser(userId).listen(
      (snapshot) {
        // Processa as leituras em sequência para não exibir a mesma notificação duas vezes.
        _processing = _processing.then((_) => _handleFeedSnapshot(userId, snapshot));
      },
      onError: (Object e) => debugPrint('Falha na escuta de notificações: $e'),
    );
  }

  // Encerra a escuta das notificações do usuário.
  void stopWatching() {
    _feedSubscription?.cancel();
    _feedSubscription = null;
    _watchedUserId = null;
    _session = null;
    _selfCreatedIds.clear();
  }

  // Carrega do aparelho a última sincronização e as notificações já tratadas para o usuário.
  Future<_WatchSession> _loadSession(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final lastShownMillis = preferences.getInt(_lastShownKey(userId));
      final lastShown = lastShownMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastShownMillis)
          : DateTime.now().subtract(_firstRunWindow);

      return _WatchSession(
        threshold: lastShown.subtract(_clockMargin),
        seenKeys: preferences.getStringList(_seenKey(userId)) ?? [],
      );
    } catch (e) {
      debugPrint('Falha ao carregar o histórico de notificações exibidas: $e');
      return _WatchSession(threshold: DateTime.now(), seenKeys: []);
    }
  }

  // Exibe as notificações ainda não tratadas de uma leitura confirmada pelo servidor e registra o progresso.
  Future<void> _handleFeedSnapshot(String userId, NotificationFeedSnapshot snapshot) async {
    try {
      if (_watchedUserId != userId) return;

      // As notificações criadas pelo próprio aparelho já tiveram aviso na tela e não são exibidas.
      _selfCreatedIds.addAll(snapshot.pendingIds);
      if (snapshot.isFromCache) return;

      final session = await _session;
      if (session == null || _watchedUserId != userId) return;

      final candidates = <NotificationModel>[];
      for (final notification in snapshot.synced) {
        // A data entra na chave para que um documento reaproveitado e renovado conte como novidade.
        final key = '${notification.id}@${notification.createdAt.millisecondsSinceEpoch}';
        if (session.seenKeys.contains(key)) continue;

        if (_selfCreatedIds.contains(notification.id)) {
          session.seenKeys.add(key);
          continue;
        }

        if (notification.read || !notification.createdAt.isAfter(session.threshold)) continue;

        candidates.add(notification);
        session.seenKeys.add(key);
      }

      if (candidates.length > _maxIndividualNotifications) {
        await show(
          id: notificationIdFor('summary:$userId'),
          title: 'Você tem ${candidates.length} novidades no Histórias de Resgate',
          body: 'Toque para ver na central de notificações.',
          payload: const LocalNotificationPayload(type: null, opensCentral: true),
        );
      } else {
        for (final notification in candidates) {
          await show(
            id: notificationIdFor(notification.id),
            title: notification.title,
            body: notification.body,
            payload: LocalNotificationPayload(
              type: notification.notificationType,
              relatedId: notification.relatedId,
              notificationId: notification.id,
            ),
          );
        }
      }

      await _saveProgress(userId, session);
    } catch (e) {
      debugPrint('Falha ao exibir as novidades no aparelho: $e');
    }
  }

  // Grava o momento da última leitura confirmada e as notificações já tratadas (as mais recentes).
  Future<void> _saveProgress(String userId, _WatchSession session) async {
    if (session.seenKeys.length > _maxSeenKeys) {
      session.seenKeys.removeRange(0, session.seenKeys.length - _maxSeenKeys);
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_lastShownKey(userId), DateTime.now().millisecondsSinceEpoch);
    await preferences.setStringList(_seenKey(userId), session.seenKeys);
  }

  static String _lastShownKey(String userId) => 'notifications_last_shown_$userId';
  static String _seenKey(String userId) => 'notifications_seen_$userId';

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
