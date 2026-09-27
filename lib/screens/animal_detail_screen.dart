import 'dart:async';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../models/adoption_request_model.dart';
import '../models/enums/adoption_status.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/ngo_service.dart';
import '../services/adoption_service.dart';
import '../services/notification_service.dart';
import '../utils/whatsapp.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/gender_tag.dart';
import '../widgets/info_banner.dart';
import '../widgets/ngo_card.dart';
import '../widgets/primary_button.dart';
import '../utils/app_feedback.dart';
import '../utils/notification_permission.dart';
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

class _AnimalDetailScreenState extends State<AnimalDetailScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final NgoService _ngoService = NgoService();
  final AdoptionService _adoptionService = AdoptionService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;

  // Indica que o WhatsApp foi aberto após uma solicitação e que a confirmação deve aparecer no retorno ao app.
  bool _awaitingWhatsAppReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Exibe a confirmação da solicitação uma única vez quando o adotante volta do WhatsApp para o aplicativo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingWhatsAppReturn) {
      _awaitingWhatsAppReturn = false;
      unawaited(_showRequestSentDialog());
    }
  }

  // Exibe o diálogo de confirmação de envio da solicitação de adoção e, em seguida,
  // pede a permissão de notificações para avisar o adotante sobre a resposta da ONG.
  Future<void> _showRequestSentDialog() async {
    if (!mounted) return;

    await showFeedbackDialog(
      context,
      title: 'Solicitação enviada!',
      message: 'A ONG vai analisar seu pedido e entrar em contato com você.',
      type: InfoBannerType.success,
    );

    if (!mounted) return;
    await askNotificationPermissionOnce(
      context,
      message: 'Quer saber quando a ONG responder? Ative as notificações para ser avisado no celular.',
    );
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
    final navigator = Navigator.of(context);

    try {
      UserModel? userModel = await _authService.getUserProfile(user.uid);

      if (userModel == null) {
        if (mounted) {
          messenger.showSnackBar(buildAppSnackBar('Não conseguimos carregar seu perfil. Tente novamente.', type: InfoBannerType.error));
        }
        return;
      }

      if (!userModel.isAdopter) {
        if (mounted) {
          messenger.showSnackBar(buildAppSnackBar('Só contas de adotante podem solicitar adoção.', type: InfoBannerType.info));
        }
        return;
      }

      // Exige o telefone do adotante antes de registrar a solicitação, para que a ONG possa retornar o contato.
      if (!userModel.hasPhone) {
        messenger.showSnackBar(buildAppSnackBar('Adicione seu telefone para que a ONG possa entrar em contato.', type: InfoBannerType.warning));

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
            messenger.showSnackBar(buildAppSnackBar('Não conseguimos carregar seu perfil. Tente novamente.', type: InfoBannerType.error));
          }
          return;
        }
      }

      final ngo = await _ngoService.getNgoById(widget.animal.ngoId);

      if (ngo == null || ngo.phone.isEmpty) {
        if (mounted) {
          messenger.showSnackBar(buildAppSnackBar('Esta ONG ainda não cadastrou um telefone para contato.', type: InfoBannerType.warning));
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

      // Avisa a ONG e confirma o envio ao adotante sem aguardar a rede, para não atrasar a abertura do WhatsApp.
      unawaited(_notificationService.notifyAdoptionRequested(
        ngoOwnerId: ngo.ownerId,
        ngoId: ngo.id,
        adopterName: adopterName,
        animal: widget.animal,
      ));
      unawaited(_notificationService.notifyAdoptionRequestSent(
        adopterId: user.uid,
        ngoName: ngo.name,
        animal: widget.animal,
      ));
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

      if (launched) {
        // A confirmação será exibida quando o adotante voltar do WhatsApp para o aplicativo.
        _awaitingWhatsAppReturn = true;
      } else if (mounted) {
        messenger.showSnackBar(buildAppSnackBar('Não conseguimos abrir o WhatsApp. Verifique se ele está instalado.', type: InfoBannerType.error));
        // A solicitação já foi registrada, então a confirmação é exibida imediatamente.
        unawaited(_showRequestSentDialog());
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(buildAppSnackBar('Não conseguimos enviar sua solicitação. Tente novamente.', type: InfoBannerType.error));
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