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
      kDebugMode ? Duration(minutes: 5) : Duration(days: 2);

  // Período após abrir "Solicitações de Adoção" em que a ONG não recebe o lembrete de pendentes.
  static const Duration recentVisitWindow =
      kDebugMode ? Duration(minutes: 3) : Duration(hours: 24);

  // Período sem usar o app após o qual o adotante é lembrado de contar como está o animal adotado.
  // O primeiro lembrete vem após 1 período e o segundo após 2, contados da última vez que usou o app.
  static const Duration adoptionInactivityPeriod =
      kDebugMode ? Duration(minutes: 10) : Duration(days: 15);

  // Tempo mínimo após a aprovação mais recente antes do primeiro lembrete de acompanhamento.
  static const Duration adoptionFollowUpMinDelay =
      kDebugMode ? Duration(minutes: 2) : Duration(days: 7);

  // Horário de silêncio dos lembretes agendados (horário do aparelho): só disparam das 9h às 19h59.
  // Fora da faixa, são movidos para as 10h. Ignorado em modo debug para não atrapalhar os testes.
  static const bool applyQuietHours = !kDebugMode;
  static const int quietHoursEnd = 9;
  static const int quietHoursStart = 20;
  static const int quietHoursRescheduleHour = 10;
}
