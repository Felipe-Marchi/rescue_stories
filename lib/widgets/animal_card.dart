import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../screens/animal_detail_screen.dart';
import 'custom_network_image.dart';

// Renderiza as informações de um animal em um contêiner visual com elevação e interação de clique.
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
      // Aplica comportamento de recorte para manter as bordas arredondadas sobre a imagem.
      clipBehavior: Clip.antiAlias,
      // Habilita o efeito cascata de clique sobre o cartão.
      child: InkWell(
        onTap: () {
          // Executa a navegação para a tela de detalhes do animal selecionado.
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
            // Delega a renderização e o tratamento de erro para o componente customizado.
            CustomNetworkImage(
              imageUrl: animal.imageUrl,
              height: 200.0,
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
      ),
    );
  }
}