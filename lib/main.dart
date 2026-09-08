import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/animal_model.dart';
import 'models/user_model.dart';
import 'widgets/animal_card.dart';
import 'services/animal_service.dart';
import 'widgets/custom_app_bar.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_animal_screen.dart';
import 'services/auth_service.dart';

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

// Apresenta a tela principal contendo a vitrine de animais disponíveis para resgate.
class HomePage extends StatelessWidget {
  // Inicializa o componente visual da tela principal.
  HomePage({super.key});

  // Instancia o servico de comunicacao com o banco de dados.
  final AnimalService _animalService = AnimalService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Define uma cor de fundo sutilmente acinzentada para destacar os cartoes brancos.
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Histórias de Resgate',
        isMainPage: true,
        // Injeta o atalho para o perfil/login na barra superior da pagina inicial.
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.green, size: 32.0),
            onPressed: () {
              if (_authService.currentUser == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      // Renderiza a lista de animais de forma reativa, escutando as atualizacoes do banco de dados.
      body: StreamBuilder<List<AnimalModel>>(
        stream: _animalService.getAnimals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os dados.'));
          }

          final animals = snapshot.data ?? [];

          if (animals.isEmpty) {
            return const Center(child: Text('Nenhum animal cadastrado ainda.'));
          }

          return ListView.builder(
            itemCount: animals.length,
            itemBuilder: (context, index) {
              return AnimalCard(animal: animals[index]);
            },
          );
        },
      ),
      // Exibe o botão flutuante de forma reativa conforme as alterações de autenticação e perfil.
      floatingActionButton: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;

          if (user == null) {
            return const SizedBox.shrink();
          }

          return FutureBuilder<UserModel?>(
            future: _authService.getUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              final userModel = profileSnapshot.data;

              if (userModel != null && userModel.isNgoRep && userModel.isActive) {
                return FloatingActionButton(
                  backgroundColor: Colors.green,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddAnimalScreen(),
                      ),
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}