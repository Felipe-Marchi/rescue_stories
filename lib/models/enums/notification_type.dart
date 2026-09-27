// Define os tipos de notificação exibidos na central de notificações do aplicativo.
enum NotificationType {
  // ONG: um adotante enviou uma nova solicitação de adoção.
  adoptionRequested,

  // Adotante: confirmação de que a solicitação foi enviada à ONG.
  adoptionRequestSent,

  // Adotante: a ONG aprovou a solicitação de adoção.
  adoptionApproved,

  // Adotante: a ONG recusou a solicitação de adoção.
  adoptionRejected,

  // Representante: a administração aprovou o cadastro da instituição.
  ngoApproved,

  // Representante: a administração reprovou o cadastro da instituição.
  ngoRejected,

  // Admin: uma instituição enviou os dados para análise.
  ngoSubmitted,

  // ONG: lembrete de solicitações pendentes há vários dias.
  pendingRequestsReminder,

  // Adotante: lembrete periódico para contar como está o animal adotado.
  adoptionFollowUpReminder,

  // Adotante e representante: boas-vindas ao concluir o cadastro.
  welcome,
}
