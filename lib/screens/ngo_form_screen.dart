import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ngo_model.dart';
import '../services/auth_service.dart';
import '../services/ngo_service.dart';
import '../services/notification_service.dart';
import '../utils/formatters.dart';
import '../utils/network.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../utils/app_feedback.dart';
import '../utils/ngo_name_words.dart';
import '../utils/notification_permission.dart';
import '../widgets/info_banner.dart';

// Renderiza a interface para o cadastro inicial ou edição dos dados institucionais da ONG.
class NgoFormScreen extends StatefulWidget {
  final NgoModel? ngoToEdit;

  const NgoFormScreen({
    super.key,
    this.ngoToEdit,
  });

  @override
  State<NgoFormScreen> createState() => _NgoFormScreenState();
}

class _NgoFormScreenState extends State<NgoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _authService = AuthService();
  final _ngoService = NgoService();
  final _notificationService = NotificationService();

  bool _isLoading = false;

  // Identificador gerado na primeira tentativa de cadastro e reutilizado nas seguintes.
  String? _pendingNgoId;

  @override
  void initState() {
    super.initState();
    if (widget.ngoToEdit != null) {
      _nameController.text = widget.ngoToEdit!.name;
      _documentController.text = widget.ngoToEdit!.document;
      _emailController.text = widget.ngoToEdit!.email;
      _phoneController.text = widget.ngoToEdit!.phone;
      _addressController.text = widget.ngoToEdit!.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Avisa os administradores sobre a nova instituição sem aguardar a rede nem interromper o envio.
  void _notifyAdminsAboutSubmission() {
    final ngoId = _pendingNgoId;
    if (ngoId == null) return;

    unawaited(_notificationService.notifyNgoSubmitted(
      ngoId: ngoId,
      ngoName: _nameController.text.trim(),
    ));
  }

  // Valida os dados, grava a instituição no banco ou atualiza o registro existente.
  Future<void> _submitNgoData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;
        String? successMessage;
        InfoBannerType messageType = InfoBannerType.success;
        bool submittedForReview = false;

        // Grava os dados no Firestore. Se expirar, as escritas permanecem na fila offline e serão sincronizadas depois.
        try {
          if (widget.ngoToEdit != null) {
            final updatedNgo = NgoModel(
              id: widget.ngoToEdit!.id,
              name: _nameController.text.trim(),
              document: _documentController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              ownerId: widget.ngoToEdit!.ownerId,
            );

            await _ngoService.updateNgo(updatedNgo);
            successMessage = 'Dados da instituição atualizados!';
          } else if (user != null) {
            // Gera o identificador uma única vez para que novas tentativas não dupliquem a instituição.
            final ngoId = _pendingNgoId ??= _ngoService.newNgoId();

            final newNgo = NgoModel(
              id: ngoId,
              name: _nameController.text.trim(),
              document: _documentController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              address: _addressController.text.trim(),
              ownerId: user.uid,
            );

            // Dispara as duas escritas juntas para que ambas entrem na fila offline mesmo sem conexão.
            await Future.wait<void>([
              _ngoService.addNgo(newNgo),
              _authService.linkUserToNgo(user.uid, ngoId),
            ]);
            submittedForReview = true;
            _notifyAdminsAboutSubmission();
          }
        } on TimeoutException {
          successMessage = 'Sem conexão. Os dados da ONG foram salvos no aparelho e serão enviados automaticamente quando a internet voltar.';
          messageType = InfoBannerType.warning;

          // No cadastro, os dados seguem na fila offline, então os administradores também são avisados.
          if (widget.ngoToEdit == null) _notifyAdminsAboutSubmission();
        }

        if (!mounted) return;

        if (submittedForReview) {
          // Confirma o envio para análise com destaque antes de fechar o formulário.
          await showFeedbackDialog(
            context,
            title: 'Cadastro enviado para análise!',
            message: 'Nossa equipe vai analisar os dados '
                '${NgoNameWords.from(_nameController.text, noun: 'instituição').withDe}. '
                'Avisaremos você pelo app.',
            type: InfoBannerType.success,
          );

          // Pede a permissão de notificações para avisar o representante sobre o resultado da análise.
          if (!mounted) return;
          await askNotificationPermissionOnce(
            context,
            title: 'Quer saber quando sua instituição for aprovada?',
            message: 'Ative as notificações e avisamos você quando a análise terminar e quando chegarem pedidos de adoção.',
          );
          if (mounted) Navigator.pop(context);
        } else if (successMessage != null) {
          showAppSnackBar(context, successMessage, type: messageType);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          final message = isConnectionError(e)
              ? noConnectionMessage
              : 'Não conseguimos salvar os dados da instituição. Tente novamente.';
          showAppSnackBar(context, message, type: InfoBannerType.error);
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
    final isEditing = widget.ngoToEdit != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: isEditing ? 'Editar Instituição' : 'Dados da Instituição',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing
                    ? 'Atualize os dados institucionais e de contato da sua organização.'
                    : 'Complete o cadastro da sua organização para poder publicar animais para adoção.',
                style: const TextStyle(
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
                validator: (value) {
                  if (value != null && value.trim().length < 3) {
                    return 'Informe o nome completo da instituição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _documentController,
                label: 'CNPJ',
                keyboardType: TextInputType.number,
                isRequired: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CnpjInputFormatter(),
                ],
                validator: (value) {
                  final digits = onlyDigits(value ?? '');
                  if (digits.length != 14) {
                    return 'CNPJ incompleto (informe os 14 dígitos)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _emailController,
                label: 'E-mail Público',
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
              const SizedBox(height: 16.0),

              CustomTextField(
                controller: _addressController,
                label: 'Endereço Completo (com Cidade/Estado)',
                isRequired: true,
                validator: (value) {
                  if (value != null && value.trim().length < 5) {
                    return 'Informe o endereço completo com Cidade/UF';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32.0),

              PrimaryButton(
                text: isEditing ? 'Salvar Alterações' : 'Enviar para Análise',
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