import 'dart:async';
import 'package:firebase_core/firebase_core.dart';

// Tempo máximo de espera por operações de rede antes de considerar o aparelho sem conexão.
const Duration networkTimeout = Duration(seconds: 15);

// Mensagem exibida quando uma operação falha por falta de conexão e nada foi gravado.
const String noConnectionMessage =
    'Sem conexão com a internet. Verifique sua rede e tente novamente.';

// Identifica se o erro recebido indica falta de conexão (timeout ou limite de tentativas do Firebase).
bool isConnectionError(Object error) {
  if (error is TimeoutException) return true;
  return error is FirebaseException &&
      const ['retry-limit-exceeded', 'unavailable', 'network-request-failed'].contains(error.code);
}
