import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

// Intercepta o fluxo de navegacao para direcionar o usuario com base no status de autenticacao.
class AuthGate extends StatelessWidget {
  AuthGate({super.key});

  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Renderiza a tela de perfil caso exista um usuario valido na sessao.
        if (snapshot.hasData) {
          return ProfileScreen();
        }

        // Renderiza a tela de login para visitantes nao autenticados.
        return const LoginScreen();
      },
    );
  }
}