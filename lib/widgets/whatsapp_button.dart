import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'secondary_button.dart';

// Renderiza o botão padronizado de contato via WhatsApp em estilo secundário, com o ícone e as cores da marca.
class WhatsAppButton extends StatelessWidget {
  // Cor oficial da marca WhatsApp, usada no contorno e no ícone.
  static const Color brandColor = Color(0xFF25D366);

  // Verde escuro da marca WhatsApp, usado no texto para garantir contraste sobre o fundo branco.
  static const Color textColor = Color(0xFF128C7E);

  final VoidCallback? onPressed;
  final String label;

  // Inicializa o componente exigindo a ação de clique e aceitando um texto personalizado.
  const WhatsAppButton({
    super.key,
    required this.onPressed,
    this.label = 'WhatsApp',
  });

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      text: label,
      color: brandColor,
      textColor: textColor,
      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20.0, color: brandColor),
      onPressed: onPressed,
    );
  }
}
