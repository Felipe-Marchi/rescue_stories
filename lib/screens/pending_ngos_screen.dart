import 'package:flutter/material.dart';
import '../models/ngo_request_model.dart';
import '../services/ngo_service.dart';
import '../widgets/custom_app_bar.dart';
import 'ngo_approval_detail_screen.dart';

// Renderiza a lista de solicitações de cadastro de ONGs pendentes de avaliação.
class PendingNgosScreen extends StatelessWidget {
  PendingNgosScreen({super.key});

  final NgoService _ngoService = NgoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Aprovação de ONGs',
      ),
      body: StreamBuilder<List<NgoRequestModel>>(
        stream: _ngoService.getPendingRequests(),
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
              child: Text(
                'Nenhuma solicitação pendente no momento.',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
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
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.business, color: Colors.white),
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
                        Text('Resp: ${request.userName} (${request.userEmail})'),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NgoApprovalDetailScreen(request: request),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}