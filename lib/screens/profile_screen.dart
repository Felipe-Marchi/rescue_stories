import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';
import 'pending_ngos_screen.dart';

// Renderiza a interface de perfil do usuario autenticado com opcoes de gerenciamento de conta.
class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Meu Perfil',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20.0),
            const Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24.0),
            const Text(
              'Bem-vindo ao Histórias de Resgate!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32.0),

            if (user != null)
              FutureBuilder<String?>(
                future: _authService.getUserRole(user.uid),
                builder: (context, snapshot) {
                  final role = snapshot.data;

                  if (role == UserRole.admin.name) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 32.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: Colors.green, size: 28),
                              SizedBox(width: 8.0),
                              Text(
                                'Painel Administrativo',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Aprovação de ONGs'),
                            subtitle: const Text('Gerenciar solicitações de cadastro pendentes'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PendingNgosScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

            // Aciona a desconexao do usuario atual e limpa a sessao ativa.
            PrimaryButton(
              text: 'Sair',
              onPressed: () async {
                await _authService.signOut();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sessão encerrada com sucesso!')),
                  );

                  // Remove a tela de perfil, voltando para o inicio
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}