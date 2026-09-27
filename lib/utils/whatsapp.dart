import 'package:url_launcher/url_launcher.dart';
import 'animal_gender_words.dart';
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

// Monta a mensagem enviada pelo adotante à ONG ao demonstrar interesse em adotar um animal.
String adoptionInterestMessage({
  required String adopterName,
  required String animalName,
  required String animalGender,
  required String email,
  required String phone,
}) {
  final words = AnimalGenderWords.fromGender(animalGender);

  return 'Olá, tudo bem?\n\n'
      'Meu nome é $adopterName e conheci ${words.article} $animalName pelo aplicativo Histórias de Resgate. '
      'Me apaixonei ${words.pronoun} e tenho muito interesse em ${words.adoptVerb}.\n\n'
      'Gostaria de saber como funciona o processo de adoção e quais são os próximos passos.\n\n'
      'Meus contatos:\n'
      'E-mail: $email\n'
      'Telefone: $phone\n\n'
      'Muito obrigado pela atenção e pelo trabalho lindo que vocês fazem!';
}

// Monta a mensagem enviada pela ONG ao adotante em resposta a uma solicitação de adoção.
String adoptionRequestReplyMessage({
  required String adopterName,
  required String ngoName,
  required String animalName,
  required String animalGender,
}) {
  final words = AnimalGenderWords.fromGender(animalGender);

  return 'Olá, $adopterName! Tudo bem?\n\n'
      'Aqui é da $ngoName. Recebemos sua solicitação de adoção ${words.contraction} $animalName '
      'pelo aplicativo Histórias de Resgate e ficamos muito felizes com o seu interesse!\n\n'
      'Podemos conversar sobre os próximos passos?';
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
