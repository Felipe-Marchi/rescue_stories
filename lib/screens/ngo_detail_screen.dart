import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dtos/ngo_request_model.dart';
import '../models/enums/user_status.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../widgets/approve_reject_buttons.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/info_banner.dart';
import '../widgets/ngo_card.dart';
import '../utils/app_feedback.dart';
import '../utils/ngo_name_words.dart';

// Renderiza a interface de exibição detalhada e avaliação de uma organização.
class NgoDetailScreen extends StatefulWidget {
  final NgoRequestModel request;

  const NgoDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<NgoDetailScreen> createState() => _NgoDetailScreenState();
}

class _NgoDetailScreenState extends State<NgoDetailScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  // Atualiza o status da solicitação e encerra a exibição da tela.
  Future<void> _processRequest(UserStatus newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserStatus(widget.request.user.id, newStatus.name);

      // Avisa o representante sobre a decisão sem aguardar a rede.
      final ngo = widget.request.ngo;
      if (newStatus == UserStatus.active) {
        unawaited(_notificationService.notifyNgoApproved(
          representativeId: widget.request.user.id,
          ngoId: ngo.id,
          ngoName: ngo.name,
        ));
      } else if (newStatus == UserStatus.rejected) {
        unawaited(_notificationService.notifyNgoRejected(
          representativeId: widget.request.user.id,
          ngoId: ngo.id,
          ngoName: ngo.name,
        ));
      }

      if (!mounted) return;

      if (newStatus == UserStatus.active) {
        await showFeedbackDialog(
          context,
          title: 'ONG aprovada!',
          message: 'Avisamos o representante. '
              '${NgoNameWords.from(ngo.name, noun: 'instituição').startOfSentence} já pode publicar animais.',
          type: InfoBannerType.success,
        );
      } else {
        await showFeedbackDialog(
          context,
          title: 'Cadastro reprovado',
          message: 'O representante foi avisado pelo app.',
          type: InfoBannerType.info,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Não conseguimos registrar a decisão. Tente novamente.', type: InfoBannerType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value.isNotEmpty ? value : 'Não informado',
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ngo = widget.request.ngo;
    final isApproved = widget.request.user.isActive;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: isApproved ? 'Detalhes da ONG' : 'Avaliação de ONG',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Renderiza o cartão com o resumo da ONG utilizando o componente isolado.
            NgoCard(
              ngo: ngo,
              title: null,
              showPhone: false,
            ),
            const SizedBox(height: 24.0),

            const Text(
              'Dados Institucionais',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            _buildDetailRow('E-mail Público', ngo.email),
            _buildDetailRow('Telefone / WhatsApp', ngo.phone),
            _buildDetailRow('Endereço Completo', ngo.address),

            const Divider(height: 32.0),

            const Text(
              'Representante Responsável',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            _buildDetailRow('Nome', widget.request.user.name),
            _buildDetailRow('E-mail da Conta', widget.request.user.email),

            const SizedBox(height: 32.0),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (isApproved)
              const InfoBanner(
                type: InfoBannerType.success,
                message: 'Instituição Aprovada e Ativa',
              )
            else
              ApproveRejectButtons(
                rejectLabel: 'Reprovar',
                onReject: () => _processRequest(UserStatus.rejected),
                onApprove: () => _processRequest(UserStatus.active),
              ),
          ],
        ),
      ),
    );
  }
}