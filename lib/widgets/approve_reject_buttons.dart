import 'package:flutter/material.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

// Renderiza o par padronizado de ações de avaliação, com a recusa em estilo secundário e a aprovação em destaque.
class ApproveRejectButtons extends StatelessWidget {
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final String approveLabel;
  final String rejectLabel;

  // Inicializa o componente com as ações de aprovar e recusar e os textos personalizáveis.
  const ApproveRejectButtons({
    super.key,
    required this.onApprove,
    required this.onReject,
    this.approveLabel = 'Aprovar',
    this.rejectLabel = 'Recusar',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            text: rejectLabel,
            color: Colors.red,
            onPressed: onReject,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: PrimaryButton(
            text: approveLabel,
            onPressed: onApprove,
          ),
        ),
      ],
    );
  }
}
