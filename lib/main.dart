import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_page.dart';

// Inicia a execução do aplicativo de forma assíncrona, estabelecendo a
// comunicação com o motor nativo e configurando os serviços do Firebase.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RescueStoriesApp());
}

// Configura o ponto de entrada principal e a estrutura visual base do aplicativo.
class RescueStoriesApp extends StatelessWidget {
  const RescueStoriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Define o nome do aplicativo no gerenciador de tarefas do dispositivo.
      title: 'Histórias de Resgate',
      theme: ThemeData(
        // Aplica a paleta de cores primária baseada em um tom de verde.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}