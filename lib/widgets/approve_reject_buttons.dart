import 'package:flutter/material.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

// Renderiza o par padronizado de ações de avaliação, com a recusa em estilo secundário e a aprovação em destaque.
class ApproveRejectButtons extends StatelessWidget {
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final String approveLabel;
  final String rejectLabel;
  final bool compact;

  // Inicializa o componente com as ações de aprovar e recusar, os textos personalizáveis e o modo compacto.
  const ApproveRejectButtons({
    super.key,
    required this.onApprove,
    required this.onReject,
    this.approveLabel = 'Aprovar',
    this.rejectLabel = 'Recusar',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final rejectButton = SecondaryButton(
      text: rejectLabel,
      color: Colors.red,
      compact: compact,
      onPressed: onReject,
    );

    final approveButton = PrimaryButton(
      text: approveLabel,
      compact: compact,
      onPressed: onApprove,
    );

    // No modo compacto, os botões ficam do tamanho do texto e quebram de linha em telas estreitas;
    // no modo normal, dividem a largura disponível.
    if (compact) {
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 8.0,
        runSpacing: 8.0,
        children: [
          rejectButton,
          approveButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: rejectButton),
        const SizedBox(width: 12.0),
        Expanded(child: approveButton),
      ],
    );
  }
}
