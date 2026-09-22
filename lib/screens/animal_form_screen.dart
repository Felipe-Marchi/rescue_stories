import 'dart:io';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/animal_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gender_selector_widget.dart';
import '../widgets/image_picker_widget.dart';
import '../widgets/primary_button.dart';

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

      final oldImageUrl = widget.animalToEdit?.imageUrl ?? "";
      String imageUrl = oldImageUrl;

      if (_isImageRemoved) {
        imageUrl = "";
      } else if (_selectedImage != null) {
        String fileName = "animal_" + DateTime.now().millisecondsSinceEpoch.toString() + ".jpg";
        imageUrl = await _storageService.uploadAnimalImage(_selectedImage!, fileName);
      }

      final user = _authService.currentUser;
      String currentNgoId = widget.animalToEdit?.ngoId ?? "";

      if (currentNgoId.isEmpty && user != null) {
        final userModel = await _authService.getUserProfile(user.uid);
        currentNgoId = userModel?.ngoId ?? '';
      }

      final animal = AnimalModel(
        id: widget.animalToEdit?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: imageUrl,
        ngoId: currentNgoId,
        gender: _selectedGender,
      );

      if (widget.animalToEdit == null) {
        await _animalService.addAnimal(animal);
      } else {
        await _animalService.updateAnimal(animal, oldImageUrl: oldImageUrl);
      }

      if (mounted) {
        final message = widget.animalToEdit == null
            ? 'Animal cadastrado com sucesso!'
            : 'Dados atualizados com sucesso!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.pop(context);
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
              GenderSelectorWidget(
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
              ImagePickerWidget(
                initialImageUrl: widget.animalToEdit?.imageUrl,
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