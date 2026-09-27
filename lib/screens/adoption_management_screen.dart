import 'package:flutter/material.dart';
import '../models/adoption_request_model.dart';
import '../models/animal_model.dart';
import '../models/enums/adoption_status.dart';
import '../models/user_model.dart';
import '../services/adoption_service.dart';
import '../services/ngo_service.dart';
import '../utils/whatsapp.dart';
import '../widgets/adoption_request_card.dart';
import '../widgets/count_pill.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/app_feedback.dart';
import '../widgets/info_banner.dart';

// Renderiza a interface de gerenciamento de solicitações de adoção recebidas por uma ONG.
class AdoptionManagementScreen extends StatefulWidget {
  final String ngoId;

  const AdoptionManagementScreen({
    super.key,
    required this.ngoId,
  });

  @override
  State<AdoptionManagementScreen> createState() => _AdoptionManagementScreenState();
}

class _AdoptionManagementScreenState extends State<AdoptionManagementScreen> {
  final AdoptionService _adoptionService = AdoptionService();
  final NgoService _ngoService = NgoService();

  late final Stream<List<AdoptionRequestModel>> _requestsStream;

  @override
  void initState() {
    super.initState();
    _requestsStream = _adoptionService.getRequestsByNgo(widget.ngoId);
  }

  // Atualiza a situação do pedido de adoção no banco de dados.
  Future<void> _processStatusChange(AdoptionRequestModel request, AdoptionStatus newStatus) async {
    try {
      await _adoptionService.updateRequestStatus(request, newStatus);
      if (!mounted) return;

      if (newStatus == AdoptionStatus.approved) {
        await showFeedbackDialog(
          context,
          title: 'Adoção aprovada!',
          message: 'Avisamos o adotante pelo app. Agora é só combinar os próximos passos pelo WhatsApp.',
          type: InfoBannerType.success,
        );
      } else {
        await showFeedbackDialog(
          context,
          title: 'Solicitação recusada',
          message: 'O adotante foi avisado pelo app.',
          type: InfoBannerType.info,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Não conseguimos atualizar a solicitação. Tente novamente.', type: InfoBannerType.error);
      }
    }
  }

  // Monta a resposta da ONG ao adotante e abre a conversa no WhatsApp.
  Future<void> _launchWhatsApp(AnimalModel? animal, UserModel? adopter) async {
    final messenger = ScaffoldMessenger.of(context);
    final rawPhone = adopter?.phone ?? '';

    if (rawPhone.isEmpty) {
      messenger.showSnackBar(buildAppSnackBar('Este adotante ainda não cadastrou um telefone.', type: InfoBannerType.warning));
      return;
    }

    // Recupera o nome da ONG aproveitando o cache do serviço.
    final ngo = await _ngoService.getNgoById(widget.ngoId);

    final message = adoptionRequestReplyMessage(
      adopterName: adopter?.name ?? '',
      ngoName: (ngo != null && ngo.name.isNotEmpty) ? ngo.name : 'ONG responsável',
      animalName: animal?.name ?? 'pet',
      animalGender: animal?.gender ?? 'Macho',
    );

    final launched = await launchWhatsApp(rawPhone, message);

    if (!launched && mounted) {
      messenger.showSnackBar(buildAppSnackBar('Não conseguimos abrir o WhatsApp. Verifique se ele está instalado.', type: InfoBannerType.error));
    }
  }

  // Constrói a aba com a lista filtrada pelo status da solicitação.
  Widget _buildRequestList({
    required List<AdoptionRequestModel> allRequests,
    required AdoptionStatus status,
    required String emptyMessage,
  }) {
    final filteredRequests =
        allRequests.where((req) => req.status == status.name).toList();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 16.0, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        final request = filteredRequests[index];

        return AdoptionRequestCard(
          request: request,
          onApprove: () => _processStatusChange(request, AdoptionStatus.approved),
          onReject: () => _processStatusChange(request, AdoptionStatus.rejected),
          onWhatsApp: (animal, adopter) => _launchWhatsApp(animal, adopter),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // O fluxo envolve toda a tela para que a aba de pendentes exiba a contagem atualizada.
    return StreamBuilder<List<AdoptionRequestModel>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];
        final pendingCount = requests
            .where((request) => request.status == AdoptionStatus.pending.name)
            .length;

        Widget body;
        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          body = const Center(child: Text('Erro ao carregar solicitações.'));
        } else {
          body = TabBarView(
            children: [
              _buildRequestList(
                allRequests: requests,
                status: AdoptionStatus.pending,
                emptyMessage: 'Nenhuma solicitação pendente no momento.',
              ),
              _buildRequestList(
                allRequests: requests,
                status: AdoptionStatus.approved,
                emptyMessage: 'Nenhuma adoção concluída ainda.',
              ),
              _buildRequestList(
                allRequests: requests,
                status: AdoptionStatus.rejected,
                emptyMessage: 'Nenhuma solicitação recusada.',
              ),
            ],
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.grey.shade100,
            appBar: CustomAppBar(
              title: 'Solicitações de Adoção',
              bottom: TabBar(
                labelColor: Colors.green,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green,
                tabs: [
                  // Exibe a quantidade de pendentes com a mesma pílula usada no painel da ONG.
                  Tab(
                    icon: const Icon(Icons.pending_actions),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pendentes'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6.0),
                          CountPill(count: pendingCount),
                        ],
                      ],
                    ),
                  ),
                  const Tab(
                    icon: Icon(Icons.check_circle_outline),
                    text: 'Aprovadas',
                  ),
                  const Tab(
                    icon: Icon(Icons.highlight_off),
                    text: 'Recusadas',
                  ),
                ],
              ),
            ),
            body: body,
          ),
        );
      },
    );
  }
}