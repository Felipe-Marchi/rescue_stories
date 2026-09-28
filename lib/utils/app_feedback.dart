import 'package:flutter/material.dart';
import '../widgets/info_banner.dart';
import '../widgets/primary_button.dart';

// Monta o aviso flutuante padronizado do aplicativo, com ícone e cores do tipo informado.
// Use diretamente com um ScaffoldMessenger capturado antes de operações assíncronas.
SnackBar buildAppSnackBar(String message, {InfoBannerType type = InfoBannerType.info}) {
  final style = InfoBannerStyle.of(type);
  final isLongLived = type == InfoBannerType.warning || type == InfoBannerType.error;

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
    backgroundColor: style.backgroundColor,
    elevation: 3.0,
    duration: Duration(seconds: isLongLived ? 5 : 3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
      side: BorderSide(color: style.borderColor),
    ),
    content: Row(
      children: [
        Icon(style.icon, color: style.accentColor, size: 24.0),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

// Exibe o aviso flutuante padronizado para confirmações do dia a dia, substituindo o aviso anterior.
void showAppSnackBar(
  BuildContext context,
  String message, {
  InfoBannerType type = InfoBannerType.info,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(buildAppSnackBar(message, type: type));
}

// Exibe o diálogo padronizado para decisões importantes; o Future termina quando o usuário toca em um botão.
// Com cancelLabel, mostra também um botão secundário; retorna true apenas quando o botão principal é tocado.
Future<bool> showFeedbackDialog(
  BuildContext context, {
  required String title,
  required String message,
  InfoBannerType type = InfoBannerType.success,
  IconData? icon,
  String confirmLabel = 'Entendi',
  String? cancelLabel,
}) async {
  final style = InfoBannerStyle.of(type);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        iconPadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
        titlePadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 8.0),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 20.0),
        icon: Container(
          width: 64.0,
          height: 64.0,
          decoration: BoxDecoration(
            color: style.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon ?? style.icon, color: style.accentColor, size: 36.0),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19.0,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.0,
            height: 1.4,
            color: Colors.grey.shade800,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
        actions: [
          // Com duas opções, empilha a ação principal e a secundária em largura total.
          if (cancelLabel != null)
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    text: confirmLabel,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  const SizedBox(height: 4.0),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      cancelLabel,
                      style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            PrimaryButton(
              text: confirmLabel,
              compact: true,
              onPressed: () => Navigator.pop(context, true),
            ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
