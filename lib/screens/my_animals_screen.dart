import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/animal_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/gender_tag.dart';
import 'animal_detail_screen.dart';
import 'animal_form_screen.dart';

// Renderiza a grade de animais cadastrados exclusivamente pela ONG autenticada.
class MyAnimalsScreen extends StatelessWidget {
  final String ngoId;
  final AnimalService _animalService = AnimalService();

  MyAnimalsScreen({
    super.key,
    required this.ngoId,
  });

  // Exibe o painel deslizante inferior com as ações disponíveis para o resgate selecionado.
  void _showOptionsBottomSheet(BuildContext context, AnimalModel animal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.green),
                  title: const Text(
                    'Editar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalFormScreen(animalToEdit: animal),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Excluir',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16.0),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, animal);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.78,
            ),
            itemCount: animals.length,
            itemBuilder: (context, index) {
              final animal = animals[index];
              return Card(
                elevation: 2.0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalDetailScreen(animal: animal),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: CustomNetworkImage(
                          imageUrl: animal.imageUrl,
                          height: double.infinity,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    animal.name,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6.0),
                                  GenderTag(gender: animal.gender),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey.shade700,
                                  size: 20.0,
                                ),
                                onPressed: () => _showOptionsBottomSheet(context, animal),
                              ),
                            ),
                          ],
                        ),
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