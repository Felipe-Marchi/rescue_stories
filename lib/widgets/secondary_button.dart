import 'package:flutter/material.dart';

// Renderiza o botão de ação secundária com contorno colorido e fundo branco, no mesmo formato do PrimaryButton.
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Widget? icon;

  // Inicializa o componente exigindo texto e ação, aceitando a cor do contorno e um ícone opcional.
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = Colors.green,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );

    final label = Text(
      text,
      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
    );

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: label,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: label,
    );
  }
}
