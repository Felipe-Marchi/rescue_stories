import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
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

                  // Exibe a ONG usando o dado desnormalizado no modelo.
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.business, color: Colors.green, size: 28.0),
                        const SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instituição Responsável',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                animal.ngoName,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Espacamento antes do botao principal
                  const SizedBox(height: 40.0),

                  // Instancia o componente padronizado para a acao de interesse do usuario.
                  PrimaryButton(
                    text: 'Quero Adotar',
                    onPressed: () {
                      if (_authService.currentUser == null) {
                        // Forca o redirecionamento para o login/cadastro caso seja um visitante.
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen(isAdoptionFlow: true)),
                        );
                      } else {
                        // Fluxo liberado para usuarios autenticados.+
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Funcionalidade de adoção em breve!')),
                        );
                      }
                    },
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