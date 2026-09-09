import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';

// Renderiza a interface visual para autenticacao de usuarios no sistema.
class LoginScreen extends StatefulWidget {
  final bool isAdoptionFlow;

  const LoginScreen({super.key, this.isAdoptionFlow = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Gerencia o estado dos campos de texto e a comunicacao com o servico de autenticacao.
class _LoginScreenState extends State<LoginScreen> {
  // Mantem a chave de identificacao global para a validacao do formulario.
  final _formKey = GlobalKey<FormState>();

  // Controla a captura de texto dos campos de email e senha.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Instancia o servico responsavel pela autenticacao no Firebase.
  final _authService = AuthService();

  bool _isLoading = false;

  // Preenche os campos de e-mail e senha com credenciais de teste de desenvolvimento.
  void _fillQuickCredentials({required String email, required String password}) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  // Executa a tentativa de login utilizando os dados inseridos pelo usuario.
  Future<void> loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Exibe um alerta visual informando o sucesso da operacao.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login realizado com sucesso!')),
          );

          // Fecha a tela de login e devolve o usuário para onde ele estava
          Navigator.pop(context);
        }
      } catch (e) {
        // Exibe um alerta visual caso as credenciais sejam invalidas ou ocorra falha na rede.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao realizar login. Verifique suas credenciais.')),
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
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _passwordController,
                label: 'Senha',
                obscureText: true,
                isRequired: true,
              ),
              const SizedBox(height: 32.0),

              PrimaryButton(
                text: 'Entrar',
                isLoading: _isLoading,
                onPressed: loginUser,
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterScreen(isAdoptionFlow: widget.isAdoptionFlow),
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

              // Renderiza os atalhos de preenchimento rápido para testes de desenvolvimento. APENAS TEMPORÁRIO!
              Container(
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
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.admin_panel_settings, size: 16.0),
                            label: const Text('Admin', style: TextStyle(fontSize: 12.0)),
                            onPressed: () {
                              _fillQuickCredentials(
                                email: 'admin@test.com',
                                password: '123456',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.business, size: 16.0),
                            label: const Text('ONG', style: TextStyle(fontSize: 12.0)),
                            onPressed: () {
                              _fillQuickCredentials(
                                email: 'teste.ong@email.com',
                                password: 'testeapp',
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}