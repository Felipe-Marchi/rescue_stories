import 'dart:async';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../models/adoption_request_model.dart';
import '../models/pet_timeline_post_model.dart';
import '../models/enums/adoption_status.dart';
import '../models/ngo_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/ngo_service.dart';
import '../services/adoption_service.dart';
import '../services/notification_service.dart';
import '../services/pet_timeline_service.dart';
import '../utils/whatsapp.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/gender_tag.dart';
import '../widgets/info_banner.dart';
import '../widgets/ngo_card.dart';
import '../widgets/pet_timeline_card.dart';
import '../widgets/primary_button.dart';
import '../utils/app_feedback.dart';
import '../utils/notification_permission.dart';
import 'login_form_screen.dart';
import 'profile_form_screen.dart';
import 'timeline_post_screen.dart';

// Renderiza a interface de exibição detalhada dos dados de um animal, linha do tempo e acionamento de adoção.
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
  final PetTimelineService _petTimelineService = PetTimelineService();

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
      title: 'Quer saber quando a ONG responder?',
      message: 'Ative as notificações e avisamos você assim que houver novidade sobre o seu pedido.',
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

  // Constrói a seção de Linha do Tempo / Histórias do Pet com a lista reativa de postagens.
  Widget _buildTimelineSection(BuildContext context) {
    final user = _authService.currentUser;

    return FutureBuilder<NgoModel?>(
      future: _ngoService.getNgoById(widget.animal.ngoId),
      builder: (context, ngoSnapshot) {
        final ngo = ngoSnapshot.data;
        final isNgoOwner = user != null && ngo != null && ngo.ownerId == user.uid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Linha do Tempo & Histórias',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Exibe o botão de adicionar foto apenas para a ONG proprietária do animal.
                if (isNgoOwner)
                  IconButton(
                    icon: const Icon(Icons.add_a_photo, color: Colors.green),
                    tooltip: 'Adicionar Foto / Atualização',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TimelinePostScreen(
                            animalId: widget.animal.id,
                            animalName: widget.animal.name,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12.0),

            StreamBuilder<List<PetTimelinePostModel>>(
              stream: _petTimelineService.getTimelineByAnimal(widget.animal.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data ?? [];

                if (posts.isEmpty) {
                  // Se for a ONG dona do pet, exibe um incentivo para publicar fotos.
                  if (isNgoOwner) {
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_a_photo_outlined, color: Colors.green, size: 28),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              'Sua instituição ainda não adicionou fotos extras para este pet. Clique no ícone de câmera acima para publicar!',
                              style: TextStyle(fontSize: 13.0, color: Colors.green.shade900),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Para visitantes e adotantes, se não houver fotos extras, mantém a tela limpa.
                  return const SizedBox.shrink();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final canManagePost = user != null && user.uid == post.authorId;

                    return PetTimelineCard(
                      post: post,
                      animalName: widget.animal.name,
                      canManage: canManagePost,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TimelinePostScreen(
                              animalId: widget.animal.id,
                              animalName: widget.animal.name,
                              postToEdit: post,
                            ),
                          ),
                        );
                      },
                      onDelete: () async {
                        try {
                          await _petTimelineService.deletePost(
                            widget.animal.id,
                            post.id,
                            imageUrl: post.imageUrl,
                          );
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              'Publicação removida da história do pet.',
                              type: InfoBannerType.success,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showAppSnackBar(
                              context,
                              'Não conseguimos remover a publicação. Tente novamente.',
                              type: InfoBannerType.error,
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
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

                  const SizedBox(height: 32.0),

                  // Exibe o botão de ação "Quero Adotar" (ou indicação de perfil não adotante) ANTES da linha do tempo.
                  _buildAdoptionActionButton(context),

                  const SizedBox(height: 32.0),

                  // Exibe a Linha do Tempo e Histórias publicadas do pet.
                  _buildTimelineSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}