import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Renderiza o botão padronizado de contato via WhatsApp com o ícone e a cor oficiais da marca.
class WhatsAppButton extends StatelessWidget {
  // Cor oficial da marca WhatsApp, reutilizada em outros pontos de contato do aplicativo.
  static const Color brandColor = Color(0xFF25D366);

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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: brandColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20.0),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  }
}
