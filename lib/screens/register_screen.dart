import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

// Renderiza a interface visual para o cadastro de novos usuarios no sistema.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  String _selectedRole = 'adopter'; // 'adopter' ou 'ngo_rep'

  // Executa o registro, gravando a autenticacao e o perfil no banco de dados.
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.registerWithEmailAndPassword(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conta criada com sucesso!')),
          );
          // Retorna para a tela de login apos o cadastro
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao criar conta. Tente novamente.')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Criar Conta',
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
                label: 'Nome Completo',
                isRequired: true,
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _passwordController,
                label: 'Senha',
                obscureText: true,
                isRequired: true,
              ),
              const SizedBox(height: 32.0),

              const Text(
                'Qual é o seu objetivo?',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),

              // Renderiza a selecao do tipo de perfil de forma clara.
              RadioListTile<String>(
                title: const Text('Quero adotar um animal'),
                value: 'adopter',
                groupValue: _selectedRole,
                activeColor: Colors.green,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Sou representante de ONG'),
                value: 'ngo_rep',
                groupValue: _selectedRole,
                activeColor: Colors.green,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              const SizedBox(height: 32.0),

              PrimaryButton(
                text: 'Cadastrar',
                isLoading: _isLoading,
                onPressed: _registerUser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}