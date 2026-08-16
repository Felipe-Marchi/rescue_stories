import 'package:flutter/material.dart';
import '../models/animal_model.dart';

// Renderiza as informações de um animal em um contêiner visual com elevação.
class AnimalCard extends StatelessWidget {
  final AnimalModel animal;

  // Inicializa o componente visual exigindo a injeção dos dados do animal.
  const AnimalCard({
    super.key,
    required this.animal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Renderiza um espaço reservado para a fotografia do animal.
          Container(
            height: 180.0,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
            ),
            child: const Icon(
              Icons.pets,
              size: 64.0,
              color: Colors.grey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exibe o nome do animal utilizando peso de fonte em negrito.
                Text(
                  animal.name,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                // Exibe a descrição do animal com limite máximo de duas linhas.
                Text(
                  animal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}