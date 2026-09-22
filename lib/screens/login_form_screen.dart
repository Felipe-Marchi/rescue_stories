import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'register_form_screen.dart';

// Renderiza a interface visual para autenticação de usuários no sistema.
class LoginFormScreen extends StatefulWidget {
  final bool isAdoptionFlow;

  const LoginFormScreen({super.key, this.isAdoptionFlow = false});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

// Gerencia o estado dos campos de texto e a comunicação com o serviço de autenticação.
class _LoginFormScreenState extends State<LoginFormScreen> {
  // Mantém a chave de identificação global para a validação do formulário.
  final _formKey = GlobalKey<FormState>();

  // Controla a captura de texto dos campos de e-mail e senha.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Instancia o serviço responsável pela autenticação no Firebase.
  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Preenche os campos de e-mail e senha com credenciais de teste de desenvolvimento.
  void _fillQuickCredentials({required String email, required String password}) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  // Exibe o diálogo para o envio de e-mail de recuperação de senha.
  void _handleForgotPassword() {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());

    showDialog(
      context: context,
      builder: (context) {
        bool isResetLoading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Redefinir Senha'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Digite seu e-mail para receber as instruções de recuperação:'),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isResetLoading
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor, informe um e-mail válido.')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isResetLoading = true;
                          });

                          try {
                            await _authService.sendPasswordResetEmail(email);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('E-mail enviado! Verifique sua caixa de entrada.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Falha ao enviar e-mail. Verifique o endereço informado.'),
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setDialogState(() {
                                isResetLoading = false;
                              });
                            }
                          }
                        },
                  child: isResetLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Executa a tentativa de login utilizando os dados inseridos pelo usuário.
  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login realizado com sucesso!')),
          );
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_authService.getLoginErrorMessage(e))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao realizar login. Tente novamente.')),
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

  // Renderiza o painel de atalhos de preenchimento rápido para testes de desenvolvimento (temporário).
  Widget _buildDevQuickLoginShortcuts() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            'Atalhos para Teste',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  ),
                  onPressed: () {
                    _fillQuickCredentials(
                      email: 'admin@test.com',
                      password: '123456',
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings, size: 14.0),
                      SizedBox(width: 4),
                      Text('Admin', style: TextStyle(fontSize: 11.0)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  ),
                  onPressed: () {
                    _fillQuickCredentials(
                      email: 'teste.ong@email.com',
                      password: 'testeapp',
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 14.0),
                      SizedBox(width: 4),
                      Text('ONG', style: TextStyle(fontSize: 11.0)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  ),
                  onPressed: () {
                    _fillQuickCredentials(
                      email: 'adotante@test.com',
                      password: '123456',
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, size: 14.0),
                      SizedBox(width: 4),
                      Text('Adotante', style: TextStyle(fontSize: 11.0)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Acesso ao Sistema',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32.0),

              CustomTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Digite um e-mail válido';
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
              ),
              const SizedBox(height: 8.0),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: Text(
                    'Esqueceu a senha?',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              PrimaryButton(
                text: 'Entrar',
                isLoading: _isLoading,
                onPressed: _loginUser,
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterFormScreen(isAdoptionFlow: widget.isAdoptionFlow),
                    ),
                  );
                },
                child: Text(
                  'Não tem uma conta? Cadastre-se',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),

              // Renderiza os atalhos temporários de teste para desenvolvimento.
              _buildDevQuickLoginShortcuts(),
            ],
          ),
        ),
      ),
    );
  }
}