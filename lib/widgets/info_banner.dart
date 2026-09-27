import 'package:flutter/material.dart';

// Define as variações visuais disponíveis para os avisos do aplicativo.
enum InfoBannerType {
  info,
  warning,
  success,
  error,
}

// Reúne as cores e o ícone padrão de cada tipo de aviso, reutilizados por outros componentes (ex.: notificações).
class InfoBannerStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;
  final IconData icon;

  const InfoBannerStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
    required this.icon,
  });

  // Retorna o estilo visual correspondente ao tipo de aviso informado.
  factory InfoBannerStyle.of(InfoBannerType type) {
    switch (type) {
      case InfoBannerType.info:
        return InfoBannerStyle(
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          accentColor: Colors.grey.shade700,
          icon: Icons.info_outline,
        );
      case InfoBannerType.warning:
        return InfoBannerStyle(
          backgroundColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade300,
          accentColor: Colors.amber.shade800,
          icon: Icons.warning_amber_rounded,
        );
      case InfoBannerType.success:
        return InfoBannerStyle(
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          accentColor: Colors.green.shade700,
          icon: Icons.check_circle,
        );
      case InfoBannerType.error:
        return InfoBannerStyle(
          backgroundColor: Colors.red.shade50,
          borderColor: Colors.red.shade200,
          accentColor: Colors.red.shade700,
          icon: Icons.error_outline,
        );
    }
  }
}

// Renderiza um aviso padronizado em caixa colorida, com ícone, título opcional, mensagem e ação opcional ao tocar.
class InfoBanner extends StatelessWidget {
  final InfoBannerType type;
  final String message;
  final String? title;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool compact;

  // Inicializa o componente exigindo o tipo e a mensagem; sem ícone informado, usa o ícone padrão do tipo.
  // O modo compacto reduz espaçamento, ícone e fonte para uso dentro de cartões de lista.
  const InfoBanner({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.icon,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = InfoBannerStyle.of(type);
    final borderRadius = BorderRadius.circular(12.0);

    final content = Container(
      padding: EdgeInsets.all(compact ? 10.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: style.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon ?? style.icon, color: style.accentColor, size: compact ? 20.0 : 28.0),
          SizedBox(width: compact ? 8.0 : 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: compact ? 13.0 : 15.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: compact ? 13.0 : 14.0,
                    color: Colors.grey.shade800,
                    fontWeight: title == null ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8.0),
            Icon(Icons.chevron_right, color: style.accentColor),
          ],
        ],
      ),
    );

    // Aplica o fundo por meio do Material para que o efeito de toque fique visível sobre a cor.
    return Material(
      color: style.backgroundColor,
      borderRadius: borderRadius,
      child: onTap == null
          ? content
          : InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: content,
            ),
    );
  }
}
