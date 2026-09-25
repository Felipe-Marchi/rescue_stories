import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../screens/animal_detail_screen.dart';
import 'custom_network_image.dart';
import 'gender_tag.dart';
import 'ngo_card.dart';

// Renderiza as informações de um animal em um contêiner visual unificado para vitrine ou gestão.
class AnimalCard extends StatelessWidget {
  final AnimalModel animal;
  final bool isCompact;
  final Widget? trailingAction;

  // Inicializa o componente visual aceitando configurações para exibição em lista detalhada ou modo compacto.
  const AnimalCard({
    super.key,
    required this.animal,
    this.isCompact = false,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: isCompact
          ? const EdgeInsets.only(bottom: 10.0)
          : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1.0,
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
        child: isCompact ? _buildCompactContent() : _buildListContent(),
      ),
    );
  }

  // Renderiza o conteúdo compacto de alta densidade adaptado para gestão da ONG.
  Widget _buildCompactContent() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CustomNetworkImage(
              imageUrl: animal.imageUrl,
              width: 60.0,
              height: 60.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  animal.name,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                GenderTag(gender: animal.gender),
              ],
            ),
          ),
          if (trailingAction != null) ...[
            const SizedBox(width: 8.0),
            trailingAction!,
          ],
        ],
      ),
    );
  }

  // Renderiza o conteúdo detalhado adaptado para listas (ex: vitrine da tela principal).
  Widget _buildListContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomNetworkImage(
          imageUrl: animal.imageUrl,
          height: 200.0,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      animal.name,
                      style: const TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  GenderTag(gender: animal.gender),
                  if (trailingAction != null) ...[
                    const SizedBox(width: 4.0),
                    trailingAction!,
                  ],
                ],
              ),
              const SizedBox(height: 6.0),
              // Exibe o nome da ONG utilizando o componente unificado em modo compacto.
              NgoCard(
                ngoId: animal.ngoId,
                isCompact: true,
              ),
              const SizedBox(height: 12.0),
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
    );
  }
}