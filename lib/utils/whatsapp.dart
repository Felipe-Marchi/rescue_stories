import 'package:url_launcher/url_launcher.dart';
import 'formatters.dart';

// Normaliza um telefone brasileiro para o formato internacional (55 + DDD + número) ou retorna null se inválido.
String? normalizeBrPhone(String phone) {
  final digits = onlyDigits(phone);

  if (digits.length == 10 || digits.length == 11) {
    return '55$digits';
  }

  if ((digits.length == 12 || digits.length == 13) && digits.startsWith('55')) {
    return digits;
  }

  return null;
}

// Abre a conversa do WhatsApp com a mensagem codificada e retorna se o aplicativo foi aberto.
Future<bool> launchWhatsApp(String phone, String message) async {
  final normalizedPhone = normalizeBrPhone(phone);
  if (normalizedPhone == null) return false;

  final encodedMessage = Uri.encodeComponent(message);
  final whatsappUri = Uri.parse('https://wa.me/$normalizedPhone?text=$encodedMessage');

  try {
    return await launchUrl(
      whatsappUri,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    return false;
  }
}
