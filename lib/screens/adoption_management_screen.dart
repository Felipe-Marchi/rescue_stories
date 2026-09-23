import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/adoption_request_model.dart';
import '../models/enums/adoption_status.dart';
import '../services/adoption_service.dart';
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

  // Formata e abre o aplicativo do WhatsApp com a mensagem codificada para o adotante.
  Future<void> _launchWhatsApp({
    required String rawPhone,
    required String animalName,
    required String adopterName,
  }) async {
    if (rawPhone.isEmpty) return;

    String phoneDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (!phoneDigits.startsWith('55') &&
        (phoneDigits.length == 10 || phoneDigits.length == 11)) {
      phoneDigits = '55$phoneDigits';
    }

    final message =
        'Olá $adopterName! Sou da ONG responsável pelo pet $animalName no Histórias de Resgate. Vamos conversar sobre a sua solicitação de adoção!';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('https://wa.me/$phoneDigits?text=$encodedMessage');

    try {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
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
          onWhatsApp: () {
            _launchWhatsApp(
              rawPhone: '',
              animalName: '',
              adopterName: '',
            );
          },
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