import 'package:flutter/material.dart';
import '../models/adoption_request_model.dart';
import '../models/animal_model.dart';
import '../models/ngo_model.dart';
import '../models/enums/adoption_status.dart';
import '../services/adoption_service.dart';
import '../services/animal_service.dart';
import '../services/ngo_service.dart';
import '../utils/formatters.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/gender_tag.dart';
import '../widgets/info_banner.dart';
import 'animal_detail_screen.dart';

// Renderiza a lista de solicitações de adoção enviadas pelo adotante autenticado.
class AdopterRequestsScreen extends StatelessWidget {
  final String adopterId;

  final AdoptionService _adoptionService = AdoptionService();
  final AnimalService _animalService = AnimalService();
  final NgoService _ngoService = NgoService();

  AdopterRequestsScreen({
    super.key,
    required this.adopterId,
  });

  Widget _buildRequestCard(BuildContext context, AdoptionRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FutureBuilder<AnimalModel?>(
          future: _animalService.getAnimalById(request.animalId),
          builder: (context, animalSnapshot) {
            final animal = animalSnapshot.data;

            return FutureBuilder<NgoModel?>(
              future: _ngoService.getNgoById(request.ngoId),
              builder: (context, ngoSnapshot) {
                final ngo = ngoSnapshot.data;

                final animalName = animal?.name ?? 'Carregando...';
                final ngoName = ngo?.name ?? 'Instituição';
                final formattedDate = formatDate(request.createdAt);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8.0),
                      onTap: animal == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnimalDetailScreen(animal: animal),
                                ),
                              );
                            },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CustomNetworkImage(
                              imageUrl: animal?.imageUrl ?? '',
                              width: 56.0,
                              height: 56.0,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        animalName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (animal != null) ...[
                                      const SizedBox(width: 6.0),
                                      GenderTag(gender: animal.gender),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  ngoName,
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  'Enviado em: $formattedDate',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 20.0),

                    if (request.status == AdoptionStatus.pending.name) ...[
                      const InfoBanner(
                        type: InfoBannerType.warning,
                        icon: Icons.hourglass_top,
                        compact: true,
                        message: 'Sua solicitação está em análise com a ONG.',
                      ),
                    ] else if (request.status == AdoptionStatus.approved.name) ...[
                      const InfoBanner(
                        type: InfoBannerType.success,
                        icon: Icons.celebration,
                        compact: true,
                        message: 'Adoção Aprovada! Parabéns pelo seu novo pet! 🎉',
                      ),
                    ] else ...[
                      const InfoBanner(
                        type: InfoBannerType.error,
                        icon: Icons.info_outline,
                        compact: true,
                        message: 'Solicitação não aprovada desta vez.',
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Minhas Solicitações',
      ),
      body: StreamBuilder<List<AdoptionRequestModel>>(
        stream: _adoptionService.streamRequestsByAdopter(adopterId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar solicitações.'));
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Você ainda não enviou solicitações de adoção. Navegue pela vitrine e escolha um pet para adotar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(context, requests[index]);
            },
          );
        },
      ),
    );
  }
}