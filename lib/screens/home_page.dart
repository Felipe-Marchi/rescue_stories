import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/animal_model.dart';
import '../models/user_model.dart';
import '../widgets/animal_card.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'animal_form_screen.dart';

// Apresenta a tela principal contendo a vitrine de animais disponíveis para resgate.
class HomePage extends StatelessWidget {
  HomePage({super.key});

  final AnimalService _animalService = AnimalService();
  final AuthService _authService = AuthService();

  // Gerencia a navegação para a tela de perfil ou login conforme o estado do usuário.
  void _handleProfileNavigation(BuildContext context) {
    if (_authService.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    }
  }

  // Constrói o botão flutuante de ação reativo para representantes de ONG ativos.
  Widget _buildFloatingActionButton() {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user == null) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<UserModel?>(
          future: _authService.getUserProfile(user.uid),
          builder: (context, profileSnapshot) {
            final userModel = profileSnapshot.data;

            if (userModel != null && userModel.isNgoRep && userModel.isActive) {
              return FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnimalFormScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Histórias de Resgate',
        isMainPage: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.green, size: 32.0),
            onPressed: () => _handleProfileNavigation(context),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: StreamBuilder<List<AnimalModel>>(
        stream: _animalService.getAnimals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os dados.'));
          }

          final animals = snapshot.data ?? [];

          if (animals.isEmpty) {
            return const Center(child: Text('Nenhum animal cadastrado ainda.'));
          }

          return ListView.builder(
            itemCount: animals.length,
            itemBuilder: (context, index) {
              return AnimalCard(animal: animals[index]);
            },
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}