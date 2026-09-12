import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';

// Renderiza a interface de visualização e gerenciamento de todos os usuários cadastrados.
class UserManagementScreen extends StatelessWidget {
  UserManagementScreen({super.key});

  final AuthService _authService = AuthService();

  Widget _buildSummaryCard(String title, int count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserModel user) {
    String label = 'Adotante';

    if (user.isAdmin) {
      label = 'Admin';
    } else if (user.isNgoRep) {
      label = 'ONG';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildStatusTag(UserModel user) {
    String label = 'Ativo';
    Color color = Colors.green.shade700;

    if (user.isUnderReview) {
      label = 'Em Análise';
      color = Colors.amber.shade800;
    } else if (user.status == 'rejected') {
      label = 'Rejeitado';
      color = Colors.red.shade700;
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const CustomAppBar(
        title: 'Usuários do Sistema',
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _authService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar usuários.'));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum usuário cadastrado no momento.',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
            );
          }

          final adoptersCount = users.where((u) => u.isAdopter).length;
          final ngoRepsCount = users.where((u) => u.isNgoRep).length;
          final adminsCount = users.where((u) => u.isAdmin).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildSummaryCard('Adotantes', adoptersCount),
                    const SizedBox(width: 8.0),
                    _buildSummaryCard('ONGs', ngoRepsCount),
                    const SizedBox(width: 8.0),
                    _buildSummaryCard('Admins', adminsCount),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      elevation: 1.0,
                      margin: const EdgeInsets.only(bottom: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade100,
                          child: Icon(
                            user.isAdmin
                                ? Icons.admin_panel_settings
                                : (user.isNgoRep ? Icons.business : Icons.person),
                            color: Colors.grey.shade700,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            _buildRoleBadge(user),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  user.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              _buildStatusTag(user),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}