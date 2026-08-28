import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/animal_model.dart';
import '../services/animal_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_app_bar.dart';

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

  File? _selectedImage;
  bool _isLoading = false;

  // Aciona a interface nativa do dispositivo para capturar ou selecionar uma imagem com base na fonte escolhida.
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Exibe um menu deslizante inferior (Bottom Sheet) para o usuario escolher entre camera e galeria.
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.green),
                title: const Text('Tirar Foto'),
                onTap: () {
                  Navigator.pop(context); // Fecha o menu deslizante.
                  _pickImage(ImageSource.camera); // Abre a camera nativa.
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context); // Fecha o menu deslizante.
                  _pickImage(ImageSource.gallery); // Abre a galeria nativa.
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Valida os dados, envia o arquivo para a nuvem e realiza a persistencia no banco de dados.
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

      final animal = AnimalModel(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: imageUrl,
      );

      await _animalService.addAnimal(animal);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // Gera a estrutura visual padronizada e minimalista para os campos de entrada.
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.green, width: 2.0),
      ),
    );
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
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('Nome do Animal'),
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20.0),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _buildInputDecoration('Descrição ou História'),
                validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 20.0),

              // Renderiza o componente de selecao de imagem, chamando o menu deslizante ao toque.
              GestureDetector(
                onTap: _showImageSourceOptions,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8.0),
                      Text(
                        'Toque para adicionar uma foto',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40.0),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveAnimal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Salvar',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}