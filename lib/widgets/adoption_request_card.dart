import 'package:flutter/material.dart';
import '../models/adoption_request_model.dart';
import '../models/animal_model.dart';
import '../models/user_model.dart';
import '../models/enums/adoption_status.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import 'custom_network_image.dart';
import 'gender_tag.dart';

// Renderiza o cartão individual com os dados combinados da solicitação de adoção, animal e adotante.
class AdoptionRequestCard extends StatelessWidget {
  final AdoptionRequestModel request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onWhatsApp;

  final AnimalService _animalService = AnimalService();
  final AuthService _authService = AuthService();

  // Inicializa o componente exigindo o modelo da solicitação e funções de ação opcionais.
  AdoptionRequestCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<AnimalModel?>(
          future: _animalService.getAnimalById(request.animalId),
          builder: (context, animalSnapshot) {
            final animal = animalSnapshot.data;

            return FutureBuilder<UserModel?>(
              future: _authService.getUserProfile(request.adopterId),
              builder: (context, adopterSnapshot) {
                final adopter = adopterSnapshot.data;

                final animalName = animal?.name ?? 'Carregando...';
                final adopterName = adopter?.name ?? 'Adotante';
                final adopterEmail = adopter?.email ?? '';
                final formattedDate = formatDate(request.createdAt);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: CustomNetworkImage(
                            imageUrl: animal?.imageUrl ?? '',
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
                                animalName,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Interessado: $adopterName',
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (adopterEmail.isNotEmpty)
                                Text(
                                  adopterEmail,
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              const SizedBox(height: 4.0),
                              Text(
                                'Data: $formattedDate',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (animal != null)
                          GenderTag(gender: animal.gender),
                      ],
                    ),
                    const Divider(height: 24.0),

                    if (request.status == AdoptionStatus.pending.name) ...[
                      Row(
                        children: [
                          if (onWhatsApp != null)
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              tooltip: 'Conversar no WhatsApp',
                              onPressed: onWhatsApp,
                            ),
                          const SizedBox(width: 8.0),
                          if (onReject != null)
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                onPressed: onReject,
                                child: const Text(
                                  'Recusar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          const SizedBox(width: 8.0),
                          if (onApprove != null)
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                onPressed: onApprove,
                                child: const Text(
                                  'Aprovar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ] else if (request.status == AdoptionStatus.approved.name) ...[
                      const ContainerStatusBadge(
                        text: 'Adoção Concluída e Aprovada',
                        color: Colors.green,
                        icon: Icons.check_circle,
                      ),
                    ] else ...[
                      const ContainerStatusBadge(
                        text: 'Solicitação Recusada',
                        color: Colors.red,
                        icon: Icons.cancel,
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
}

// Renderiza uma badge de indicação visual de status da solicitação.
class ContainerStatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const ContainerStatusBadge({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.0),
          const SizedBox(width: 8.0),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }
}