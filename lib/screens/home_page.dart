import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/animal_model.dart';
import '../models/user_model.dart';
import '../widgets/animal_card.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/notification_bell.dart';
import 'login_form_screen.dart';
import 'profile_screen.dart';
import 'animal_form_screen.dart';

// Apresenta a tela principal contendo as abas de animais disponíveis e histórias de sucesso (adotados).
class HomePage extends StatelessWidget {
  HomePage({super.key});

  final AnimalService _animalService = AnimalService();
  final AuthService _authService = AuthService();

  // Gerencia a navegação para a tela de perfil ou login conforme o estado do usuário.
  void _handleProfileNavigation(BuildContext context) {
    if (_authService.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginFormScreen()),
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

  // Constrói a lista reativa de animais para a aba selecionada.
  Widget _buildAnimalList(Stream<List<AnimalModel>> stream, String emptyMessage) {
    return StreamBuilder<List<AnimalModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar os dados.'));
        }

        final animals = snapshot.data ?? [];

        if (animals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: animals.length,
          itemBuilder: (context, index) {
            return AnimalCard(animal: animals[index]);
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
        appBar: CustomAppBar(
          title: 'Histórias de Resgate',
          isMainPage: true,
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(
                icon: Icon(Icons.pets),
                text: 'Disponíveis',
              ),
              Tab(
                icon: Icon(Icons.celebration),
                text: 'Adotados',
              ),
            ],
          ),
          actions: [
            // Exibe o sino de notificações apenas para usuários autenticados.
            const NotificationBell(),
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.green, size: 32.0),
              onPressed: () => _handleProfileNavigation(context),
            ),
            const SizedBox(width: 8.0),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAnimalList(
              _animalService.getAnimals(),
              'Nenhum animal disponível no momento.',
            ),
            _buildAnimalList(
              _animalService.getAdoptedAnimals(),
              'Nenhum animal foi marcado como adotado ainda.',
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }
}