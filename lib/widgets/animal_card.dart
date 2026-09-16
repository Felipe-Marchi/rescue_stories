import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../models/ngo_model.dart';
import '../screens/animal_detail_screen.dart';
import '../services/ngo_service.dart';
import 'custom_network_image.dart';
import 'gender_tag.dart';

// Renderiza as informações de um animal em um contêiner visual unificado para vitrine ou gestão.
class AnimalCard extends StatelessWidget {
  final AnimalModel animal;
  final bool isGrid;
  final Widget? trailingAction;

  final NgoService _ngoService = NgoService();

  // Inicializa o componente visual aceitando configurações para exibição em lista ou grade.
  AnimalCard({
    super.key,
    required this.animal,
    this.isGrid = false,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: isGrid
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        child: isGrid ? _buildGridContent() : _buildListContent(),
      ),
    );
  }

  // Renderiza o conteúdo compacto adaptado para grades (ex: tela de gestão).
  Widget _buildGridContent() {
    return Column(
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
              if (trailingAction != null) ...[
                trailingAction!,
              ],
            ],
          ),
        ),
      ],
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
                    ),
                  ),
                  GenderTag(gender: animal.gender),
                ],
              ),
              const SizedBox(height: 6.0),
              FutureBuilder<NgoModel?>(
                future: _ngoService.getNgoById(animal.ngoId),
                builder: (context, snapshot) {
                  final ngo = snapshot.data;
                  final ngoName = ngo != null && ngo.name.isNotEmpty
                      ? ngo.name
                      : (snapshot.connectionState == ConnectionState.waiting
                          ? 'Carregando...'
                          : 'ONG não vinculada');

                  return Row(
                    children: [
                      const Icon(Icons.business, size: 14.0, color: Colors.green),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          ngoName,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
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