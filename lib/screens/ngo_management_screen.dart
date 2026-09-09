import 'package:flutter/material.dart';
import '../models/dtos/ngo_request_model.dart';
import '../services/ngo_service.dart';
import '../widgets/custom_app_bar.dart';
import 'ngo_detail_screen.dart';

// Renderiza a interface de gerenciamento de ONGs com abas para solicitações pendentes e aprovadas.
class NgoManagementScreen extends StatelessWidget {
  NgoManagementScreen({super.key});

  final NgoService _ngoService = NgoService();

  Widget _buildNgoList({
    required BuildContext context,
    required Stream<List<NgoRequestModel>> stream,
    required String emptyMessage,
    required bool isApprovedTab,
  }) {
    return StreamBuilder<List<NgoRequestModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar dados.'));
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16.0, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                leading: CircleAvatar(
                  backgroundColor: isApprovedTab ? Colors.green : Colors.amber.shade700,
                  child: Icon(
                    isApprovedTab ? Icons.check_circle : Icons.business,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  request.ngo.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CNPJ: ${request.ngo.document}'),
                      const SizedBox(height: 2.0),
                      Text('Resp: ${request.user.name} (${request.user.email})'),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NgoDetailScreen(request: request),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: const CustomAppBar(
          title: 'Gerenciamento de ONGs',
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
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNgoList(
              context: context,
              stream: _ngoService.getPendingRequests(),
              emptyMessage: 'Nenhuma solicitação pendente no momento.',
              isApprovedTab: false,
            ),
            _buildNgoList(
              context: context,
              stream: _ngoService.getApprovedRequests(),
              emptyMessage: 'Nenhuma ONG aprovada cadastrada.',
              isApprovedTab: true,
            ),
          ],
        ),
      ),
    );
  }
}