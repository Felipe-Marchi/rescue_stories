import 'package:flutter/material.dart';

// Define as variações visuais disponíveis para os avisos do aplicativo.
enum InfoBannerType {
  info,
  warning,
  success,
  error,
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

  // Retorna a cor de fundo correspondente ao tipo do aviso.
  Color get _backgroundColor {
    switch (type) {
      case InfoBannerType.info:
        return Colors.grey.shade100;
      case InfoBannerType.warning:
        return Colors.amber.shade50;
      case InfoBannerType.success:
        return Colors.green.shade50;
      case InfoBannerType.error:
        return Colors.red.shade50;
    }
  }

  // Retorna a cor da borda correspondente ao tipo do aviso.
  Color get _borderColor {
    switch (type) {
      case InfoBannerType.info:
        return Colors.grey.shade300;
      case InfoBannerType.warning:
        return Colors.amber.shade300;
      case InfoBannerType.success:
        return Colors.green.shade200;
      case InfoBannerType.error:
        return Colors.red.shade200;
    }
  }

  // Retorna a cor de destaque (ícones) correspondente ao tipo do aviso.
  Color get _accentColor {
    switch (type) {
      case InfoBannerType.info:
        return Colors.grey.shade700;
      case InfoBannerType.warning:
        return Colors.amber.shade800;
      case InfoBannerType.success:
        return Colors.green.shade700;
      case InfoBannerType.error:
        return Colors.red.shade700;
    }
  }

  // Retorna o ícone padrão correspondente ao tipo do aviso.
  IconData get _defaultIcon {
    switch (type) {
      case InfoBannerType.info:
        return Icons.info_outline;
      case InfoBannerType.warning:
        return Icons.warning_amber_rounded;
      case InfoBannerType.success:
        return Icons.check_circle;
      case InfoBannerType.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12.0);

    final content = Container(
      padding: EdgeInsets.all(compact ? 10.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Icon(icon ?? _defaultIcon, color: _accentColor, size: compact ? 20.0 : 28.0),
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
            Icon(Icons.chevron_right, color: _accentColor),
          ],
        ],
      ),
    );

    // Aplica o fundo por meio do Material para que o efeito de toque fique visível sobre a cor.
    return Material(
      color: _backgroundColor,
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
