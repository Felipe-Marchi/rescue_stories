import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';

// Renderiza a interface de visualização e gerenciamento de todos os usuários cadastrados.
class UserManagementScreen extends StatelessWidget {
  UserManagementScreen({super.key});

  final AuthService _authService = AuthService();

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserModel user) {
    String label = 'Adotante';
    Color color = Colors.green;

    if (user.isAdmin) {
      label = 'Admin';
      color = Colors.purple;
    } else if (user.isNgoRep) {
      label = 'ONG';
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusTag(UserModel user) {
    String label = 'Ativo';
    Color color = Colors.green;

    if (user.isUnderReview) {
      label = 'Em Análise';
      color = Colors.amber.shade800;
    } else if (user.status == 'rejected') {
      label = 'Rejeitado';
      color = Colors.red;
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
                    _buildSummaryCard('Adotantes', adoptersCount, Colors.green),
                    const SizedBox(width: 8.0),
                    _buildSummaryCard('ONGs', ngoRepsCount, Colors.blue),
                    const SizedBox(width: 8.0),
                    _buildSummaryCard('Admins', adminsCount, Colors.purple),
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
                      margin: const EdgeInsets.only(bottom: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(
                            user.isAdmin
                                ? Icons.admin_panel_settings
                                : (user.isNgoRep ? Icons.business : Icons.person),
                            color: user.isAdmin
                                ? Colors.purple
                                : (user.isNgoRep ? Colors.blue : Colors.green),
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