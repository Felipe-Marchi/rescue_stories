import 'package:flutter/material.dart';
import '../models/animal_model.dart';

// Renderiza a interface de exibição detalhada dos dados de um animal específico.
class AnimalDetailScreen extends StatelessWidget {
  final AnimalModel animal;

  // Inicializa a tela exigindo o modelo de dados do animal selecionado.
  const AnimalDetailScreen({
    super.key,
    required this.animal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Define o nome do animal como título da barra superior.
        title: Text(animal.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // Renderiza o conteúdo em formato de rolagem vertical.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exibe a imagem em destaque ocupando grande parte superior da tela.
            Image.network(
              animal.imageUrl,
              height: 300.0,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Renderiza o nome completo em formato de título primário.
                  Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Exibe a descrição completa do animal sem limitação de linhas.
                  Text(
                    animal.description,
                    style: const TextStyle(
                      fontSize: 16.0,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}