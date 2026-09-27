import 'package:flutter/material.dart';

// Renderiza o botão de ação secundária com contorno colorido e fundo branco, no mesmo formato do PrimaryButton.
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final Color? textColor;
  final Widget? icon;
  final bool compact;

  // Inicializa o componente exigindo texto e ação, aceitando a cor do contorno, um ícone opcional,
  // uma cor de texto própria (quando omitida, o texto usa a mesma cor do contorno) e o modo compacto para listas.
  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = Colors.green,
    this.textColor,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: textColor ?? color,
      side: BorderSide(color: color, width: 1.5),
      // No modo compacto, reduz a altura e adiciona margem lateral, pois o botão não ocupa a largura toda.
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0)
          : const EdgeInsets.symmetric(vertical: 16.0),
      iconSize: compact ? 16.0 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );

    final label = Text(
      text,
      style: TextStyle(
        fontSize: compact ? 14.0 : 16.0,
        fontWeight: FontWeight.bold,
      ),
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
