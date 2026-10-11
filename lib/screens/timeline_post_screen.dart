import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pet_timeline_post_model.dart';
import '../models/enums/user_role.dart';
import '../services/auth_service.dart';
import '../services/pet_timeline_service.dart';
import '../services/storage_service.dart';
import '../utils/app_feedback.dart';
import '../utils/network.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/info_banner.dart';
import '../widgets/primary_button.dart';

// Renderiza a interface de formulário para adicionar ou editar uma foto/história na linha do tempo do animal.
class TimelinePostScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final PetTimelinePostModel? postToEdit;

  const TimelinePostScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    this.postToEdit,
  });

  @override
  State<TimelinePostScreen> createState() => _TimelinePostScreenState();
}

class _TimelinePostScreenState extends State<TimelinePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final PetTimelineService _petTimelineService = PetTimelineService();

  File? _selectedImage;
  bool _isImageRemoved = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.postToEdit != null) {
      _captionController.text = widget.postToEdit!.caption;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // Valida os dados, faz upload/atualização da imagem no Storage e salva a postagem na subcoleção.
  Future<void> _savePost() async {
    final isEditing = widget.postToEdit != null;
    final oldImageUrl = widget.postToEdit?.imageUrl ?? '';

    // No modo cadastro, a foto é obrigatória
    if (!isEditing && _selectedImage == null) {
      showAppSnackBar(
        context,
        'Selecione uma foto para publicar na história do pet.',
        type: InfoBannerType.warning,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;
        if (user == null) return;

        final userModel = await _authService.getUserProfile(user.uid);

        String imageUrl = oldImageUrl;

        if (_isImageRemoved) {
          imageUrl = '';
        } else if (_selectedImage != null) {
          final fileName = 'timeline_${DateTime.now().millisecondsSinceEpoch}.jpg';
          imageUrl = await _storageService.uploadAnimalImage(_selectedImage!, fileName);
        }

        if (isEditing) {
          final updatedPost = PetTimelinePostModel(
            id: widget.postToEdit!.id,
            animalId: widget.animalId,
            authorId: widget.postToEdit!.authorId,
            authorRole: widget.postToEdit!.authorRole,
            imageUrl: imageUrl,
            caption: _captionController.text.trim(),
            createdAt: widget.postToEdit!.createdAt,
          );

          await _petTimelineService.updatePost(updatedPost, oldImageUrl: oldImageUrl);
        } else {
          final newPost = PetTimelinePostModel(
            id: '',
            animalId: widget.animalId,
            authorId: user.uid,
            authorRole: userModel?.role ?? UserRole.adopter.name,
            imageUrl: imageUrl,
            caption: _captionController.text.trim(),
            createdAt: DateTime.now(),
          );

          await _petTimelineService.addPost(newPost);
        }

        if (mounted) {
          final successMessage = isEditing
              ? 'Atualização da história salva com sucesso!'
              : 'Nova foto adicionada à história de ${widget.animalName}!';
          showAppSnackBar(
            context,
            successMessage,
            type: InfoBannerType.success,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          final message = isConnectionError(e)
              ? noConnectionMessage
              : 'Não conseguimos salvar a atualização. Tente novamente.';
          showAppSnackBar(context, message, type: InfoBannerType.error);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.postToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: isEditing ? 'Editar História' : 'Nova História de ${widget.animalName}',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing
                    ? 'Atualize a foto ou a legenda da história do pet.'
                    : 'Compartilhe uma foto e conte como o pet está acompanhando o dia a dia.',
                style: const TextStyle(
                  fontSize: 15.0,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24.0),

              // Campo para seleção de foto com suporte a imagem existente e remoção
              ImagePickerField(
                initialImageUrl: widget.postToEdit?.imageUrl,
                onImageSelected: (file) {
                  setState(() {
                    _selectedImage = file;
                    if (file != null) _isImageRemoved = false;
                  });
                },
                onImageRemoved: () {
                  setState(() {
                    _selectedImage = null;
                    _isImageRemoved = true;
                  });
                },
              ),
              const SizedBox(height: 20.0),

              // Campo para legenda ou história da publicação
              CustomTextField(
                controller: _captionController,
                label: 'Legenda ou História',
                maxLines: 3,
                isRequired: true,
                validator: (value) {
                  if (value != null && value.trim().length < 3) {
                    return 'Escreva uma legenda simples sobre a foto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),

              PrimaryButton(
                text: isEditing ? 'Salvar Alterações' : 'Publicar Atualização',
                isLoading: _isLoading,
                onPressed: _savePost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}