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
            ],
          ),
        ),
      ),
    );
  }
}