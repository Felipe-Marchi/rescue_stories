import 'package:flutter/material.dart';

// Renderiza o botao de acao principal do aplicativo com suporte a estado de carregamento.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;
  final Widget? icon;
  final bool compact;

  // Inicializa o componente exigindo texto e acao, gerenciando a trava de clique durante operacoes.
  // Aceita opcionalmente uma cor de fundo, um ícone exibido antes do texto e o modo compacto para listas.
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color = Colors.green,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      // No modo compacto, reduz a altura e adiciona margem lateral, pois o botão não ocupa a largura toda.
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0)
          : const EdgeInsets.symmetric(vertical: 16.0),
      iconSize: compact ? 16.0 : null,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );

    final spinnerSize = compact ? 18.0 : 24.0;

    final label = isLoading
        ? SizedBox(
            height: spinnerSize,
            width: spinnerSize,
            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
        : Text(
            text,
            style: TextStyle(
              fontSize: compact ? 14.0 : 16.0,
              fontWeight: FontWeight.bold,
            ),
          );

    if (icon != null && !isLoading) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon!,
        label: label,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: label,
    );
  }
}
