import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'whatsapp_button.dart';

// Renderiza o atalho compacto e redondo de contato via WhatsApp, para uso ao lado de telefones em listas.
class WhatsAppIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  // Inicializa o componente exigindo a ação de clique e aceitando um texto de dica personalizado.
  const WhatsAppIconButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Conversar no WhatsApp',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      // Mantém a área de toque mínima de 40x40 com fundo verde claro da marca.
      style: IconButton.styleFrom(
        backgroundColor: WhatsAppButton.brandColor.withAlpha(31),
        minimumSize: const Size(40.0, 40.0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(8.0),
        shape: const CircleBorder(),
      ),
      icon: const FaIcon(
        FontAwesomeIcons.whatsapp,
        size: 18.0,
        color: WhatsAppButton.brandColor,
      ),
    );
  }
}
