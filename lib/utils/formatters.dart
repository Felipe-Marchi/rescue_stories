import 'package:flutter/services.dart';

// Remove todos os caracteres não numéricos do texto informado.
String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

// Formata uma instância de DateTime no formato textual padrão dd/mm/yyyy.
String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return "$day/$month/${date.year}";
}

// Formata uma data em texto relativo ao momento atual ("agora", "há 5 min", "ontem", "há 3 dias"),
// usando o formato dd/mm/yyyy para datas com uma semana ou mais.
String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inMinutes < 1) return 'agora';
  if (difference.inMinutes < 60) return 'há ${difference.inMinutes} min';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final daysAgo = today.difference(day).inDays;

  if (daysAgo == 0) return 'há ${difference.inHours} h';
  if (daysAgo == 1) return 'ontem';
  if (daysAgo < 7) return 'há $daysAgo dias';
  return formatDate(date);
}

// Formata a entrada de texto do campo de CNPJ aplicando a máscara XX.XXX.XXX/XXXX-XX.
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = onlyDigits(newValue.text);
    final limited = digitsOnly.length > 14 ? digitsOnly.substring(0, 14) : digitsOnly;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formata a entrada de texto do campo de telefone/WhatsApp aplicando a máscara (XX) XXXXX-XXXX.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = onlyDigits(newValue.text);
    final limited = digitsOnly.length > 11 ? digitsOnly.substring(0, 11) : digitsOnly;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (limited.length <= 10) {
        if (i == 6) buffer.write('-');
      } else {
        if (i == 7) buffer.write('-');
      }
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}