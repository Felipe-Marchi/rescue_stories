import 'dart:io';
import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/animal_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/image_picker_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

// Renderiza a interface de formulario para o cadastro de um animal no sistema.
class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

// Gerencia o estado interno, selecao de midia e as interacoes do formulario de cadastro.
class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _animalService = AnimalService();
  final _storageService = StorageService();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;

  File? _selectedImage;
  bool _isLoading = false;

  // Valida os dados, realiza o upload da imagem, recupera o vinculo institucional e persiste o cadastro.
  Future<void> _saveAnimal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String imageUrl = "";

      if (_selectedImage != null) {
        String fileName = "animal_" + DateTime.now().millisecondsSinceEpoch.toString() + ".jpg";
        imageUrl = await _storageService.uploadAnimalImage(_selectedImage!, fileName);
      }

      // Consulta o documento do usuario atual para obter o identificador da ONG vinculada.
      final user = _authService.currentUser;
      String currentNgoId = "";

      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        currentNgoId = userDoc.data()?['ngoId'] ?? '';
      }

      final animal = AnimalModel(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: imageUrl,
        ngoId: currentNgoId,
      );

      await _animalService.addAnimal(animal);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Cadastrar Animal',
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