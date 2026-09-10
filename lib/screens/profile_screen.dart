import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';
import 'ngo_management_screen.dart';
import 'user_management_screen.dart';
import 'my_animals_screen.dart';
import 'animal_form_screen.dart';

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
              FutureBuilder<UserModel?>(
                future: _authService.getUserProfile(user.uid),
                builder: (context, snapshot) {
                  final userModel = snapshot.data;

                  if (userModel == null) {
                    return const SizedBox.shrink();
                  }

                  if (userModel.isAdmin) {
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
                            title: const Text('Gerenciar ONGs'),
                            subtitle: const Text('Aprovação e consulta de instituições cadastradas'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NgoManagementScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Usuários do Sistema'),
                            subtitle: const Text('Visualizar todas as contas registradas'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserManagementScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  if (userModel.isNgoRep) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 32.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: userModel.isActive ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: userModel.isActive ? Colors.green.shade200 : Colors.amber.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: userModel.isActive ? Colors.green : Colors.amber.shade800,
                                size: 28,
                              ),
                              const SizedBox(width: 8.0),
                              const Text(
                                'Painel da Instituição',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),

                          if (userModel.isActive && userModel.ngoId != null) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Meus Animais Cadastrados'),
                              subtitle: const Text('Visualizar, editar e remover resgates'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyAnimalsScreen(
                                      ngoId: userModel.ngoId!,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Cadastrar Novo Animal'),
                              subtitle: const Text('Publicar um novo animal para adoção'),
                              trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AnimalFormScreen(),
                                  ),
                                );
                              },
                            ),
                          ] else if (userModel.isUnderReview) ...[
                            const Text(
                              'Cadastro em Análise',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Sua instituição foi enviada para análise da administração. Em breve você receberá a liberação para publicar animais.',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ] else ...[
                            const Text(
                              'Cadastro Não Aprovado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Sua solicitação de cadastro não foi aprovada. Entre em contato com o suporte para mais informações.',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
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