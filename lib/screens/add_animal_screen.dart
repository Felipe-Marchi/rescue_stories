import 'dart:io';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/animal_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/image_picker_widget.dart';
import '../services/auth_service.dart';

// Renderiza a interface de formulário para o cadastro e edição de um animal no sistema.
class AddAnimalScreen extends StatefulWidget {
  final AnimalModel? animalToEdit;

  const AddAnimalScreen({
    super.key,
    this.animalToEdit,
  });

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

// Gerencia o estado interno, seleção de mídia e as interações do formulário de cadastro/edição.
class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _animalService = AnimalService();
  final _storageService = StorageService();
  final _authService = AuthService();

  File? _selectedImage;
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

  // Valida os dados, realiza o upload da imagem e persiste o cadastro ou alteração.
  Future<void> _saveAnimal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String imageUrl = widget.animalToEdit?.imageUrl ?? "";

      if (_selectedImage != null) {
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
        await _animalService.updateAnimal(animal);
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

              // Renderiza os seletores de sexo do animal.
              const Text(
                'Sexo do Animal',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Macho')),
                      selected: _selectedGender == 'Macho',
                      selectedColor: Colors.green.shade100,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedGender = 'Macho';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Fêmea')),
                      selected: _selectedGender == 'Fêmea',
                      selectedColor: Colors.green.shade100,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedGender = 'Fêmea';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              CustomTextField(
                controller: _descriptionController,
                label: 'Descrição ou História',
                maxLines: 4,
                isRequired: true,
              ),
              const SizedBox(height: 20.0),

              // Instancia o componente isolado recebendo o arquivo pelo callback.
              ImagePickerWidget(
                onImageSelected: (file) {
                  _selectedImage = file;
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