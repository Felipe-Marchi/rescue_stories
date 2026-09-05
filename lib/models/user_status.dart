// Define estritamente a fase atual da conta do usuario, sem misturar com o seu papel (role).
enum UserStatus {
  // Conta totalmente liberada (Adotante pode adotar; ONG aprovada pode cadastrar animais).
  active,

  // Conta criada, mas o usuario ainda precisa preencher dados obrigatorios complementares.
  pendingSetup,

  // Dados enviados, aguardando aprovacao manual da equipe administradora.
  underReview,

  // Acesso negado pela administracao (ex: CNPJ invalido).
  rejected,
}