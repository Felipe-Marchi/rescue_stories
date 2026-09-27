import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import '../utils/network.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

// Renderiza a interface de formulário para a edição do nome e do telefone do usuário autenticado.
class ProfileFormScreen extends StatefulWidget {
  final UserModel user;

  const ProfileFormScreen({
    super.key,
    required this.user,
  });

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _emailController.text = widget.user.email;
    _phoneController.text = widget.user.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Valida os dados e grava o nome e o telefone no perfil do usuário, retornando true à tela anterior.
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        String message;

        // Grava os dados no Firestore. Se expirar, a escrita permanece na fila offline e será sincronizada depois.
        try {
          await _authService.updateUserProfile(
            widget.user.id,
            _nameController.text.trim(),
            _phoneController.text.trim(),
          );
          message = 'Perfil atualizado com sucesso!';
        } on TimeoutException {
          message = 'Sem conexão. Seu perfil foi salvo no aparelho e será enviado automaticamente quando a internet voltar.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          final message = isConnectionError(e)
              ? noConnectionMessage
              : 'Falha ao atualizar o perfil. Tente novamente.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
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
        title: 'Editar Perfil',
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

              // Exibe o e-mail apenas para consulta, pois ele é a credencial de acesso da conta.
              CustomTextField(
                controller: _emailController,
                label: 'E-mail',
                readOnly: true,
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _phoneController,
                label: 'Telefone / WhatsApp',
                keyboardType: TextInputType.phone,
                isRequired: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  PhoneInputFormatter(),
                ],
                validator: (value) {
                  final digits = onlyDigits(value ?? '');
                  if (digits.length < 10) {
                    return 'Informe um telefone válido com DDD';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),

              PrimaryButton(
                text: 'Salvar Alterações',
                isLoading: _isLoading,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
