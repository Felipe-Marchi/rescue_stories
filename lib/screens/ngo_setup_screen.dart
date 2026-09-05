import 'package:flutter/material.dart';
import '../models/ngo_model.dart';
import '../services/auth_service.dart';
import '../services/ngo_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

// Renderiza a interface para o cadastro inicial obrigatorio dos dados da instituicao.
class NgoSetupScreen extends StatefulWidget {
  const NgoSetupScreen({super.key});

  @override
  State<NgoSetupScreen> createState() => _NgoSetupScreenState();
}

class _NgoSetupScreenState extends State<NgoSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _authService = AuthService();
  final _ngoService = NgoService();

  bool _isLoading = false;

  // Valida os dados, grava a instituicao no banco e vincula ao usuario atual.
  Future<void> _submitNgoData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;

        if (user != null) {
          final newNgo = NgoModel(
            id: '',
            name: _nameController.text.trim(),
            document: _documentController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            address: _addressController.text.trim(),
            ownerId: user.uid,
          );

          // Salva a organizacao e recupera o identificador gerado pelo Firestore.
          final ngoId = await _ngoService.addNgo(newNgo);

          // Vincula o identificador da ONG ao usuario e atualiza o status para analise.
          await _authService.linkUserToNgo(user.uid, ngoId);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dados enviados com sucesso! Aguarde a aprovação.')),
            );
            // Retorna para a tela principal (HomePage) que ficou na base da navegacao.
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha ao enviar os dados. Tente novamente.')),
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
        title: 'Dados da Instituição',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete o cadastro da sua organização para poder publicar animais para adoção.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24.0),

              CustomTextField(
                controller: _nameController,
                label: 'Nome da Instituição',
                isRequired: true,
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _documentController,
                label: 'CNPJ',
                isRequired: true,
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _emailController,
                label: 'E-mail Público',
                keyboardType: TextInputType.emailAddress,
                isRequired: true,
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _phoneController,
                label: 'Telefone / WhatsApp',
                keyboardType: TextInputType.phone,
                isRequired: true,
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _addressController,
                label: 'Endereço Completo (com Cidade/Estado)',
                isRequired: true,
              ),
              const SizedBox(height: 32.0),

              PrimaryButton(
                text: 'Enviar para Análise',
                isLoading: _isLoading,
                onPressed: _submitNgoData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}