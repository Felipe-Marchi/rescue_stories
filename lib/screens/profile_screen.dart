import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

// Renderiza a interface de perfil do usuario autenticado com opcoes de gerenciamento de conta.
class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Meu Perfil',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: 40.0),

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