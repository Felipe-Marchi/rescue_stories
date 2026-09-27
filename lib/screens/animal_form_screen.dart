import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/animal_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../utils/network.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gender_selector.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/primary_button.dart';
import '../utils/app_feedback.dart';
import '../widgets/info_banner.dart';

// Renderiza a interface de formulário para o cadastro e edição de um animal no sistema.
class AnimalFormScreen extends StatefulWidget {
  final AnimalModel? animalToEdit;

  const AnimalFormScreen({
    super.key,
    this.animalToEdit,
  });

  @override
  State<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

// Gerencia o estado interno, seleção de mídia e as interações do formulário de cadastro/edição.
class _AnimalFormScreenState extends State<AnimalFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _animalService = AnimalService();
  final _storageService = StorageService();
  final _authService = AuthService();

  File? _selectedImage;
  bool _isImageRemoved = false;
  String _selectedGender = 'Macho';
  bool _isLoading = false;

  // Identificador gerado na primeira tentativa de cadastro e reutilizado nas seguintes.
  String? _pendingAnimalId;

  // URL da foto já enviada ao Storage, reutilizada caso a gravação no banco precise ser repetida.
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.animalToEdit != null) {
      _nameController.text = widget.animalToEdit!.name;
      _descriptionController.text = widget.animalToEdit!.description;
      _selectedGender = widget.animalToEdit!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Valida os dados, realiza o upload ou remoção da imagem e persiste o cadastro ou alteração.
  Future<void> _saveAnimal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final isEditing = widget.animalToEdit != null;

      try {
        // Etapa 1: operações de rede que ainda não gravam nada no banco (upload da foto e leitura do perfil).
        final oldImageUrl = widget.animalToEdit?.imageUrl ?? "";
        String imageUrl = oldImageUrl;

        if (_isImageRemoved) {
          imageUrl = "";
        } else if (_selectedImage != null) {
          // Reaproveita a foto já enviada em uma tentativa anterior que falhou depois do upload.
          if (_uploadedImageUrl == null) {
            final fileName = 'animal_${DateTime.now().millisecondsSinceEpoch}.jpg';
            _uploadedImageUrl = await _storageService.uploadAnimalImage(_selectedImage!, fileName);
          }
          imageUrl = _uploadedImageUrl!;
        }

        final user = _authService.currentUser;
        String currentNgoId = widget.animalToEdit?.ngoId ?? "";

        if (currentNgoId.isEmpty && user != null) {
          final userModel = await _authService.getUserProfile(user.uid).timeout(networkTimeout);
          currentNgoId = userModel?.ngoId ?? '';
        }

        // Gera o identificador uma única vez para que novas tentativas não dupliquem o cadastro.
        final animalId = widget.animalToEdit?.id ?? (_pendingAnimalId ??= _animalService.newAnimalId());

        final animal = AnimalModel(
          id: animalId,
          name: _nameController.text,
          description: _descriptionController.text,
          imageUrl: imageUrl,
          ngoId: currentNgoId,
          gender: _selectedGender,
        );

        // Etapa 2: gravação no Firestore. Se expirar, a escrita permanece na fila offline e será sincronizada depois.
        String message;
        InfoBannerType messageType = InfoBannerType.success;
        try {
          if (isEditing) {
            await _animalService.updateAnimal(animal, oldImageUrl: oldImageUrl);
          } else {
            await _animalService.addAnimal(animal);
          }
          message = isEditing
              ? 'Dados de ${animal.name} atualizados!'
              : '${animal.name} já aparece na vitrine!';
        } on TimeoutException {
          message = 'Sem conexão. O animal foi salvo no aparelho e será enviado automaticamente quando a internet voltar.';
          messageType = InfoBannerType.warning;
        }

        if (mounted) {
          showAppSnackBar(context, message, type: messageType);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          final message = isConnectionError(e)
              ? noConnectionMessage
              : 'Não conseguimos salvar o animal. Tente novamente.';
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
    final isEditing = widget.animalToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: isEditing ? 'Editar Animal' : 'Cadastrar Animal',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Nome do Animal',
                isRequired: true,
              ),
              const SizedBox(height: 20.0),

              // Renderiza o seletor de sexo do animal via componente isolado.
              GenderSelector(
                selectedGender: _selectedGender,
                onGenderSelected: (gender) {
                  setState(() {
                    _selectedGender = gender;
                  });
                },
              ),
              const SizedBox(height: 20.0),

              CustomTextField(
                controller: _descriptionController,
                label: 'Descrição ou História',
                maxLines: 4,
                isRequired: true,
              ),
              const SizedBox(height: 20.0),

              // Instancia o componente de foto com suporte à imagem inicial e remoção.
              ImagePickerField(
                initialImageUrl: widget.animalToEdit?.imageUrl,
                onImageSelected: (file) {
                  setState(() {
                    _selectedImage = file;
                    _uploadedImageUrl = null;
                    if (file != null) _isImageRemoved = false;
                  });
                },
                onImageRemoved: () {
                  setState(() {
                    _selectedImage = null;
                    _uploadedImageUrl = null;
                    _isImageRemoved = true;
                  });
                },
              ),
              const SizedBox(height: 40.0),

              PrimaryButton(
                text: 'Salvar',
                isLoading: _isLoading,
                onPressed: _saveAnimal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}