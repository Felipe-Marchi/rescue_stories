import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/database_service.dart';

// Renderiza a interface de formulário para o cadastro de um animal no sistema.
class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

// Gerencia o estado interno e as interações do formulário de cadastro.
class _AddAnimalScreenState extends State<AddAnimalScreen> {
  // Mantém a chave de identificação global para a validação do formulário.
  final _formKey = GlobalKey<FormState>();

  // Controla a captura de texto dos campos de entrada de dados.
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Instancia o serviço de comunicação com o banco de dados.
  final _databaseService = DatabaseService();

  // Valida os dados inseridos e realiza a persistência no banco de dados.
  void _saveAnimal() {
    if (_formKey.currentState!.validate()) {
      final animal = AnimalModel(
        id: '',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: _imageUrlController.text,
      );

      _databaseService.addAnimal(animal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Define o título de exibição na barra de navegação superior.
        title: const Text('Cadastrar Resgate'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Renderiza o campo de entrada para o nome do animal.
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Animal'),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16.0),
              // Renderiza o campo de entrada para a descrição do animal.
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16.0),
              // Renderiza o campo de entrada para a URL da imagem.
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'URL da Imagem (Link)'),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 32.0),
              // Renderiza o botão de ação para submissão do formulário.
              ElevatedButton(
                onPressed: _saveAnimal,
                child: const Text('Salvar Cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}