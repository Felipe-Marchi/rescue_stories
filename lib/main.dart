import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/animal_model.dart';
import 'widgets/animal_card.dart';

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

  // Instancia uma lista em memória com dados simulados de animais para exibição.
  final List<AnimalModel> mockAnimals = [
    AnimalModel(
      id: '1',
      name: 'Rex',
      description: 'Cachorro dócil e brincalhão, adora correr no parque e interagir com outros cães.',
      imageUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=600&auto=format&fit=crop',
    ),
    AnimalModel(
      id: '2',
      name: 'Mia',
      description: 'Gata calma que prefere lugares tranquilos e passar a tarde dormindo no sofá.',
      imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?q=80&w=600&auto=format&fit=crop',
    ),
    AnimalModel(
      id: '3',
      name: 'Thor',
      description: 'Filhote cheio de energia, ideal para casas com quintal grande e famílias ativas.',
      imageUrl: 'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?q=80&w=600&auto=format&fit=crop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Aplica a cor invertida do esquema de cores na barra superior.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Define o título de exibição na barra de navegação superior.
        title: const Text('Histórias de Resgate'),
      ),
      // Constrói uma lista rolável para renderizar os cartões dos animais.
      body: ListView.builder(
        itemCount: mockAnimals.length,
        itemBuilder: (context, index) {
          return AnimalCard(animal: mockAnimals[index]);
        },
      ),
    );
  }
}