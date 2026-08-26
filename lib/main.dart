import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/animal_model.dart';
import 'widgets/animal_card.dart';
import 'screens/add_animal_screen.dart';
import 'services/animal_service.dart';

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

  // Instancia o serviço de comunicação com o banco de dados.
  final AnimalService _animalService = AnimalService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Aplica a cor invertida do esquema de cores na barra superior.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Define o título de exibição na barra de navegação superior.
        title: const Text('Histórias de Resgate'),
      ),
      // Renderiza a lista de animais de forma reativa, escutando as atualizações do banco de dados.
      body: StreamBuilder<List<AnimalModel>>(
        stream: _animalService.getAnimals(),
        builder: (context, snapshot) {
          // Exibe um indicador de carregamento enquanto aguarda a resposta do servidor.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Exibe uma mensagem de erro caso ocorra falha na comunicação.
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os dados.'));
          }

          final animals = snapshot.data ?? [];

          // Exibe uma mensagem amigável caso o banco de dados esteja vazio.
          if (animals.isEmpty) {
            return const Center(child: Text('Nenhum animal cadastrado ainda.'));
          }

          // Constrói uma lista rolável para renderizar os cartões dos animais recuperados.
          return ListView.builder(
            itemCount: animals.length,
            itemBuilder: (context, index) {
              return AnimalCard(animal: animals[index]);
            },
          );
        },
      ),
      // Renderiza o botão de ação flutuante para acessar a tela de cadastro.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Executa a navegação para a interface de formulário.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAnimalScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}