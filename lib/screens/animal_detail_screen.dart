import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/animal_model.dart';
import '../models/adoption_request_model.dart';
import '../models/enums/adoption_status.dart';
import '../services/auth_service.dart';
import '../services/ngo_service.dart';
import '../services/adoption_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/gender_tag.dart';
import '../widgets/ngo_card.dart';
import '../widgets/primary_button.dart';
import 'login_form_screen.dart';

// Renderiza a interface de exibição detalhada dos dados de um animal e o acionamento de adoção.
class AnimalDetailScreen extends StatefulWidget {
  final AnimalModel animal;

  const AnimalDetailScreen({
    super.key,
    required this.animal,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final AuthService _authService = AuthService();
  final NgoService _ngoService = NgoService();
  final AdoptionService _adoptionService = AdoptionService();

  bool _isLoading = false;

  // Formata o número de telefone e abre o aplicativo do WhatsApp com a mensagem codificada.
  Future<void> _launchWhatsApp({
    required String rawPhone,
    required String animalName,
    required String adopterName,
    required String adopterEmail,
    required ScaffoldMessengerState messenger,
  }) async {
    String phoneDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (!phoneDigits.startsWith('55') &&
        (phoneDigits.length == 10 || phoneDigits.length == 11)) {
      phoneDigits = '55$phoneDigits';
    }

    final message =
        'Olá! Tenho interesse em adotar o pet $animalName que vi no Histórias de Resgate. Meu nome é $adopterName ($adopterEmail). Gostaria de saber os próximos passos!';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('https://wa.me/$phoneDigits?text=$encodedMessage');

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o aplicativo do WhatsApp.')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Verifique se o aplicativo do WhatsApp está instalado.')),
        );
      }
    }
  }

  // Gerencia o registro da intenção de adoção e a abertura do WhatsApp da ONG.
  Future<void> _handleAdoption(BuildContext context) async {
    final user = _authService.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginFormScreen(isAdoptionFlow: true),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final userModel = await _authService.getUserProfile(user.uid);
      final ngo = await _ngoService.getNgoById(widget.animal.ngoId);

      if (ngo == null || ngo.phone.isEmpty) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('A ONG responsável não possui telefone cadastrado.')),
          );
        }
        return;
      }

      // Registra a solicitação de intenção no banco de dados com status pendente.
      final request = AdoptionRequestModel(
        id: '',
        animalId: widget.animal.id,
        adopterId: user.uid,
        ngoId: widget.animal.ngoId,
        status: AdoptionStatus.pending.name,
        createdAt: DateTime.now(),
      );

      await _adoptionService.createAdoptionRequest(request);

      final adopterName = userModel?.name ?? 'Um adotante';
      final adopterEmail = userModel?.email ?? user.email ?? '';

      // Formata a mensagem e redireciona para a conversa com a ONG no WhatsApp.
      await _launchWhatsApp(
        rawPhone: ngo.phone,
        animalName: widget.animal.name,
        adopterName: adopterName,
        adopterEmail: adopterEmail,
        messenger: messenger,
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Falha ao registrar solicitação de adoção. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              imageUrl: widget.animal.imageUrl,
              height: 300.0,
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.animal.name,
                          style: const TextStyle(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      GenderTag(
                        gender: widget.animal.gender,
                        isLarge: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    widget.animal.description,
                    style: TextStyle(
                      fontSize: 16.0,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Exibe as informações da ONG responsável através do componente isolado.
                  NgoCard(ngoId: widget.animal.ngoId),

                  const SizedBox(height: 40.0),

                  PrimaryButton(
                    text: 'Quero Adotar',
                    isLoading: _isLoading,
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