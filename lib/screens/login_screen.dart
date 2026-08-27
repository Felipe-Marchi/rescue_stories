import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// Renderiza a interface visual para autenticacao de usuarios no sistema.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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

  // Executa a tentativa de login utilizando os dados inseridos pelo usuario.
  Future<void> loginUser() async {
    if (_formKey.currentState!.validate()) {
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
        }
      } catch (e) {
        // Exibe um alerta visual caso as credenciais sejam invalidas ou ocorra falha na rede.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao realizar login. Verifique suas credenciais.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso ao Sistema'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Renderiza o campo de entrada formatado para enderecos de email.
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Informe seu e-mail' : null,
              ),
              const SizedBox(height: 16.0),
              // Renderiza o campo de entrada de texto oculto para senhas.
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Informe sua senha' : null,
              ),
              const SizedBox(height: 24.0),
              // Renderiza o botao de acao principal para submissao do formulario.
              ElevatedButton(
                onPressed: loginUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}