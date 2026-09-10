import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../models/enums/user_role.dart';
import 'ngo_setup_screen.dart';

// Renderiza a interface visual para o cadastro de novos usuários no sistema.
class RegisterScreen extends StatefulWidget {
  final bool isAdoptionFlow;

  const RegisterScreen({super.key, this.isAdoptionFlow = false});

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
  String _selectedRole = UserRole.adopter.name;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Mapeia exceções do Firebase Auth para mensagens amigáveis de cadastro.
  String _getRegisterErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Faça login ou use outro e-mail.';
      case 'invalid-email':
        return 'O e-mail digitado não é válido.';
      case 'weak-password':
        return 'A senha escolhida é muito fraca. Escolha uma senha mais forte.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      default:
        return 'Falha ao criar conta. Tente novamente.';
    }
  }

  // Executa o registro, gravando a autenticação e o perfil no banco de dados.
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
          if (_selectedRole == UserRole.ngoRep.name) {
            // Direciona o representante para o preenchimento obrigatório dos dados da ONG.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conta criada! Finalize os dados da instituição.')),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const NgoSetupScreen()),
              (route) => route.isFirst,
            );
          } else {
            // Retorna o adotante para a tela anterior.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conta criada com sucesso!')),
            );
            Navigator.of(context)..pop()..pop();
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_getRegisterErrorMessage(e))),
          );
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

  Widget _buildRoleCard({
    required String title,
    required String description,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedRole == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: isSelected ? Colors.green : Colors.grey.shade400),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green.shade800 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                validator: (value) {
                  if (value != null && value.trim().length < 3) {
                    return 'Informe seu nome completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Informe um e-mail válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _passwordController,
                label: 'Senha',
                obscureText: true,
                isRequired: true,
                validator: (value) {
                  if (value != null && value.length < 6) {
                    return 'A senha deve ter no mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),

              if (!widget.isAdoptionFlow) ...[
                const Text(
                  'Qual é o seu objetivo?',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),

                _buildRoleCard(
                  title: 'Quero adotar um animal',
                  description: 'Navegue, favorite e entre em contato com ONGs.',
                  icon: Icons.pets,
                  value: UserRole.adopter.name,
                ),
                const SizedBox(height: 12.0),

                _buildRoleCard(
                  title: 'Sou representante de ONG',
                  description: 'Cadastre resgates e gerencie processos de adoção.',
                  icon: Icons.business,
                  value: UserRole.ngoRep.name,
                ),
                const SizedBox(height: 32.0),
              ],

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