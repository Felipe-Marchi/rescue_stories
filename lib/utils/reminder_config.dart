import 'package:flutter/foundation.dart';

// Centraliza os prazos dos lembretes; em modo debug usa valores curtos para permitir o teste no aparelho.
class ReminderConfig {
  // Tempo a partir do qual uma solicitação pendente é considerada sem resposta.
  static const Duration pendingRequestThreshold =
      kDebugMode ? Duration(minutes: 2) : Duration(days: 3);

  // Texto do prazo acima, usado na mensagem do lembrete da ONG.
  static const String pendingRequestThresholdLabel = kDebugMode ? '2 minutos' : '3 dias';

  // Intervalo mínimo entre dois lembretes de solicitações pendentes para a mesma ONG.
  static const Duration ngoReminderInterval =
      kDebugMode ? Duration(minutes: 1) : Duration(days: 1);

  // Intervalo de repetição do lembrete para o adotante contar como está o animal adotado.
  static const Duration adoptionFollowUpInterval =
      kDebugMode ? Duration(minutes: 2) : Duration(days: 15);
}
