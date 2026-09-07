import 'package:flutter/material.dart';
import '../models/dtos/ngo_request_model.dart';
import '../models/enums/user_status.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';

// Renderiza a interface de avaliação detalhada de uma solicitação de ONG.
class NgoApprovalDetailScreen extends StatefulWidget {
  final NgoRequestModel request;

  const NgoApprovalDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<NgoApprovalDetailScreen> createState() => _NgoApprovalDetailScreenState();
}

class _NgoApprovalDetailScreenState extends State<NgoApprovalDetailScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Atualiza o status da solicitação e encerra a exibição da tela.
  Future<void> _processRequest(UserStatus newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserStatus(widget.request.user.id, newStatus.name);

      if (mounted) {
        final message = newStatus == UserStatus.active
            ? 'ONG aprovada com sucesso!'
            : 'Solicitação reprovada.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao processar solicitação.')),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Avaliação de ONG',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: Colors.green, size: 32),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ngo.name,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'CNPJ: ${ngo.document}',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () => _processRequest(UserStatus.rejected),
                      child: const Text(
                        'Reprovar',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Aprovar',
                      onPressed: () => _processRequest(UserStatus.active),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}