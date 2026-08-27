import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/animal_model.dart';
import 'widgets/animal_card.dart';
import 'screens/add_animal_screen.dart';
import 'services/animal_service.dart';
import 'widgets/custom_app_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Define uma cor de fundo sutilmente acinzentada para destacar os cartoes brancos.
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Histórias de Resgate',
        isMainPage: true,
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
      // Renderiza o botao administrativo para adicionar novos resgates.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAnimalScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4.0,
        child: const Icon(Icons.add),
      ),
    );
  }
}