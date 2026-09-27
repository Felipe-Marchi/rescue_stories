import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../models/adoption_request_model.dart';
import '../models/enums/adoption_status.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/ngo_service.dart';
import '../services/adoption_service.dart';
import '../utils/whatsapp.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/gender_tag.dart';
import '../widgets/info_banner.dart';
import '../widgets/ngo_card.dart';
import '../widgets/primary_button.dart';
import 'login_form_screen.dart';
import 'profile_form_screen.dart';

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
    final navigator = Navigator.of(context);

    try {
      UserModel? userModel = await _authService.getUserProfile(user.uid);

      if (userModel == null) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Não foi possível carregar seu perfil. Tente novamente.')),
          );
        }
        return;
      }

      if (!userModel.isAdopter) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Apenas contas de Adotantes podem solicitar adoção.')),
          );
        }
        return;
      }

      // Exige o telefone do adotante antes de registrar a solicitação, para que a ONG possa retornar o contato.
      if (!userModel.hasPhone) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Adicione seu telefone para que a ONG possa entrar em contato.')),
        );

        final profileToEdit = userModel;
        final saved = await navigator.push<bool>(
          MaterialPageRoute(
            builder: (context) => ProfileFormScreen(user: profileToEdit),
          ),
        );

        // Encerra sem criar a solicitação caso o adotante volte sem salvar o telefone.
        if (saved != true) return;

        // Recarrega o perfil atualizado e continua o fluxo automaticamente.
        userModel = await _authService.getUserProfile(user.uid);

        if (userModel == null || !userModel.hasPhone) {
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Não foi possível carregar seu perfil. Tente novamente.')),
            );
          }
          return;
        }
      }

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

      final adopterName = userModel.name;
      final adopterEmail = userModel.email.isNotEmpty ? userModel.email : (user.email ?? '');
      final adopterPhone = userModel.phone ?? '';

      // Formata a mensagem e redireciona para a conversa com a ONG no WhatsApp.
      final message = adoptionInterestMessage(
        adopterName: adopterName,
        animalName: widget.animal.name,
        animalGender: widget.animal.gender,
        email: adopterEmail,
        phone: adopterPhone,
      );

      final launched = await launchWhatsApp(ngo.phone, message);

      if (!launched && mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o aplicativo do WhatsApp.')),
        );
      }
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

  // Constrói o elemento visual do botão de adoção ou mensagem explicativa conforme o perfil do usuário.
  Widget _buildAdoptionActionButton(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return PrimaryButton(
        text: 'Quero Adotar',
        isLoading: _isLoading,
        onPressed: () => _handleAdoption(context),
      );
    }

    return FutureBuilder<UserModel?>(
      future: _authService.getUserProfile(user.uid),
      builder: (context, snapshot) {
        final userModel = snapshot.data;

        if (userModel == null) {
          return PrimaryButton(
            text: 'Quero Adotar',
            isLoading: _isLoading,
            onPressed: () => _handleAdoption(context),
          );
        }

        if (!userModel.isAdopter) {
          return const InfoBanner(
            type: InfoBannerType.info,
            message: 'Adoção disponível apenas para contas de Adotantes.',
          );
        }

        return PrimaryButton(
          text: 'Quero Adotar',
          isLoading: _isLoading,
          onPressed: () => _handleAdoption(context),
        );
      },
    );
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

                  // Exibe o botão de ação ou a indicação de perfil não adotante.
                  _buildAdoptionActionButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}