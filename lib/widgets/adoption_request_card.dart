import 'package:flutter/material.dart';
import '../models/adoption_request_model.dart';
import '../models/animal_model.dart';
import '../models/user_model.dart';
import '../models/enums/adoption_status.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import 'approve_reject_buttons.dart';
import 'custom_network_image.dart';
import 'gender_tag.dart';
import 'info_banner.dart';
import 'whatsapp_button.dart';

// Renderiza o cartão individual com os dados combinados da solicitação de adoção, animal e adotante.
class AdoptionRequestCard extends StatelessWidget {
  final AdoptionRequestModel request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  // Recebe o animal e o adotante já carregados pelo cartão para iniciar a conversa no WhatsApp.
  final void Function(AnimalModel? animal, UserModel? adopter)? onWhatsApp;

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
                              // Exibe o telefone do adotante ou indica a ausência do contato em contas antigas.
                              if (adopter != null)
                                Text(
                                  adopter.hasPhone ? adopter.phone! : 'Telefone não informado',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    color: Colors.grey.shade600,
                                    fontStyle: adopter.hasPhone ? FontStyle.normal : FontStyle.italic,
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
                      // Exibe o contato via WhatsApp em linha própria, habilitado após o carregamento do adotante.
                      if (onWhatsApp != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: WhatsAppButton(
                            onPressed: adopter == null ? null : () => onWhatsApp!(animal, adopter),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                      ],
                      ApproveRejectButtons(
                        onApprove: onApprove,
                        onReject: onReject,
                      ),
                    ] else if (request.status == AdoptionStatus.approved.name) ...[
                      const InfoBanner(
                        type: InfoBannerType.success,
                        message: 'Adoção Concluída e Aprovada',
                      ),
                    ] else ...[
                      const InfoBanner(
                        type: InfoBannerType.error,
                        icon: Icons.cancel,
                        message: 'Solicitação Recusada',
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
