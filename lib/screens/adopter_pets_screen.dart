import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/animal_service.dart';
import '../widgets/animal_card.dart';
import '../widgets/custom_app_bar.dart';
import 'timeline_post_screen.dart';

// Renderiza a lista de animais adotados pelo adotante autenticado com atalho para publicar na linha do tempo.
class AdopterPetsScreen extends StatelessWidget {
  final String adopterId;
  final AnimalService _animalService = AnimalService();

  AdopterPetsScreen({
    super.key,
    required this.adopterId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Meus Pets Adotados',
      ),
      body: StreamBuilder<List<AnimalModel>>(
        stream: _animalService.getAnimalsByAdopter(adopterId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar pets adotados.'));
          }

          final animals = snapshot.data ?? [];

          if (animals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Você ainda não possui pets adotados. Quando sua solicitação de adoção for aprovada pela ONG, seu novo pet aparecerá aqui! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];

              return AnimalCard(
                animal: animal,
                isCompact: true,
                trailingAction: IconButton(
                  icon: const Icon(Icons.add_a_photo, color: Colors.green),
                  tooltip: 'Postar Foto na História',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TimelinePostScreen(
                          animalId: animal.id,
                          animalName: animal.name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}