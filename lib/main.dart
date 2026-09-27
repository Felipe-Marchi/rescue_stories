import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_page.dart';
import 'services/auth_service.dart';
import 'services/local_notification_service.dart';
import 'utils/notification_navigation.dart';

// Inicia a execução do aplicativo de forma assíncrona, estabelecendo a
// comunicação com o motor nativo e configurando os serviços do Firebase.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalNotificationService().initialize(onTap: openLocalNotification);
  runApp(const RescueStoriesApp());
}

// Configura o ponto de entrada principal e a estrutura visual base do aplicativo.
// Também acompanha a sessão para ligar ou desligar as notificações do aparelho.
class RescueStoriesApp extends StatefulWidget {
  const RescueStoriesApp({super.key});

  @override
  State<RescueStoriesApp> createState() => _RescueStoriesAppState();
}

class _RescueStoriesAppState extends State<RescueStoriesApp> {
  final AuthService _authService = AuthService();
  final LocalNotificationService _localNotificationService = LocalNotificationService();

  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges.listen(_handleAuthChange);

    // Abre a tela da notificação que iniciou o aplicativo, depois que a Home estiver montada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launchPayload = _localNotificationService.takeLaunchPayload();
      if (launchPayload != null) openLocalNotification(launchPayload);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _localNotificationService.stopWatching();
    super.dispose();
  }

  // Liga a escuta de notificações para o usuário conectado ou limpa tudo ao sair da conta.
  void _handleAuthChange(User? user) {
    if (user == null) {
      _localNotificationService.stopWatching();
      unawaited(_localNotificationService.cancelAll());
      return;
    }

    _localNotificationService.startWatching(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Define o nome do aplicativo no gerenciador de tarefas do dispositivo.
      title: 'Histórias de Resgate',
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      theme: ThemeData(
        // Aplica a paleta de cores primária baseada em um tom de verde.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}
