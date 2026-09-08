import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/animal_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/gender_tag.dart';
import 'add_animal_screen.dart';

// Renderiza a lista de animais cadastrados exclusivamente pela ONG autenticada.
class MyAnimalsScreen extends StatelessWidget {
  final String ngoId;
  final AnimalService _animalService = AnimalService();

  MyAnimalsScreen({
    super.key,
    required this.ngoId,
  });

  // Exibe o diálogo de confirmação para a exclusão do registro.
  void _confirmDelete(BuildContext context, AnimalModel animal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Registro'),
          content: Text('Tem certeza que deseja excluir ${animal.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _animalService.deleteAnimal(animal.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registro removido com sucesso.')),
                  );
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Meus Animais Cadastrados',
      ),
      body: StreamBuilder<List<AnimalModel>>(
        stream: _animalService.getAnimalsByNgo(ngoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar animais.'));
          }

          final animals = snapshot.data ?? [];

          if (animals.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum animal cadastrado ainda.',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CustomNetworkImage(
                          imageUrl: animal.imageUrl,
                          height: 70.0,
                          width: 70.0,
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              animal.name,
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            GenderTag(gender: animal.gender),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAnimalScreen(animalToEdit: animal),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, animal),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}