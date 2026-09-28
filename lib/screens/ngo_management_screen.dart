import 'package:flutter/material.dart';
import '../models/dtos/ngo_request_model.dart';
import '../services/ngo_service.dart';
import '../utils/notification_permission.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/ngo_card.dart';
import 'ngo_detail_screen.dart';

// Renderiza a interface de gerenciamento de ONGs com abas para solicitações pendentes e aprovadas.
class NgoManagementScreen extends StatefulWidget {
  const NgoManagementScreen({super.key});

  @override
  State<NgoManagementScreen> createState() => _NgoManagementScreenState();
}

class _NgoManagementScreenState extends State<NgoManagementScreen> {
  final NgoService _ngoService = NgoService();

  @override
  void initState() {
    super.initState();
    // Pede a permissão de notificações para avisar o administrador sobre novas instituições.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      askNotificationPermissionOnce(
        context,
        title: 'Novas instituições para aprovar',
        message: 'Ative as notificações e avisamos você quando uma instituição enviar o cadastro para análise.',
      );
    });
  }

  Widget _buildNgoList({
    required BuildContext context,
    required Stream<List<NgoRequestModel>> stream,
    required String emptyMessage,
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: NgoCard(
                ngo: request.ngo,
                title: null,
                showPhone: false,
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
            ),
            _buildNgoList(
              context: context,
              stream: _ngoService.getApprovedRequests(),
              emptyMessage: 'Nenhuma ONG aprovada cadastrada.',
            ),
          ],
        ),
      ),
    );
  }
}