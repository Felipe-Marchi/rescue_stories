import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/ngo_info_card.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

// Renderiza a interface de exibição detalhada dos dados de um animal específico.
class AnimalDetailScreen extends StatelessWidget {
  final AnimalModel animal;
  final AuthService _authService = AuthService();

  // Inicializa a tela exigindo o modelo de dados do animal selecionado.
  AnimalDetailScreen({
    super.key,
    required this.animal,
  });

  // Gerencia o fluxo de ação do botão de adoção conforme a autenticação.
  void _handleAdoption(BuildContext context) {
    if (_authService.currentUser == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(isAdoptionFlow: true),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidade de adoção em breve!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Detalhes',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomNetworkImage(
              imageUrl: animal.imageUrl,
              height: 300.0,
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    animal.description,
                    style: TextStyle(
                      fontSize: 16.0,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Exibe as informações da ONG responsável através do componente isolado.
                  NgoInfoCard(ngoId: animal.ngoId),

                  const SizedBox(height: 40.0),

                  PrimaryButton(
                    text: 'Quero Adotar',
                    onPressed: () => _handleAdoption(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}