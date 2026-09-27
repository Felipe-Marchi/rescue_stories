import 'package:flutter/material.dart';
import '../models/adoption_request_model.dart';
import '../models/animal_model.dart';
import '../models/enums/adoption_status.dart';
import '../models/user_model.dart';
import '../services/adoption_service.dart';
import '../services/ngo_service.dart';
import '../utils/whatsapp.dart';
import '../widgets/adoption_request_card.dart';
import '../widgets/custom_app_bar.dart';

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

  // Atualiza a situação do pedido de adoção no banco de dados.
  Future<void> _processStatusChange(String requestId, AdoptionStatus newStatus) async {
    try {
      await _adoptionService.updateRequestStatus(requestId, newStatus);
      if (mounted) {
        final message = newStatus == AdoptionStatus.approved
            ? 'Adoção aprovada com sucesso!'
            : 'Solicitação recusada.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao atualizar status da solicitação.')),
        );
      }
    }
  }

  // Monta a resposta da ONG ao adotante e abre a conversa no WhatsApp.
  Future<void> _launchWhatsApp(AnimalModel? animal, UserModel? adopter) async {
    final messenger = ScaffoldMessenger.of(context);
    final rawPhone = adopter?.phone ?? '';

    if (rawPhone.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Este adotante ainda não possui telefone cadastrado.')),
      );
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
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
          onApprove: () => _processStatusChange(request.id, AdoptionStatus.approved),
          onReject: () => _processStatusChange(request.id, AdoptionStatus.rejected),
          onWhatsApp: (animal, adopter) => _launchWhatsApp(animal, adopter),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: const CustomAppBar(
          title: 'Solicitações de Adoção',
          bottom: TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(
                icon: Icon(Icons.pending_actions),
                text: 'Pendentes',
              ),
              Tab(
                icon: Icon(Icons.check_circle_outline),
                text: 'Aprovadas',
              ),
              Tab(
                icon: Icon(Icons.highlight_off),
                text: 'Recusadas',
              ),
            ],
          ),
        ),
        body: StreamBuilder<List<AdoptionRequestModel>>(
          stream: _adoptionService.getRequestsByNgo(widget.ngoId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Erro ao carregar solicitações.'));
            }

            final requests = snapshot.data ?? [];

            return TabBarView(
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
          },
        ),
      ),
    );
  }
}