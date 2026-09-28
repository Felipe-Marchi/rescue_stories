// Monta referências ao nome da ONG com o artigo correto, acrescentando um substantivo ("ONG" ou
// "instituição") apenas quando o nome ainda não começa com um (ex.: "Instituto Patinhas" já traz o seu).
class NgoNameWords {
  // Termo que precede o nome (substantivo acrescentado + nome, ou só o nome) e se ele é masculino.
  final String phrase;
  final bool isMasculine;

  const NgoNameWords._({required this.phrase, required this.isMasculine});

  // Substantivos reconhecidos no início do nome, sem diferenciar maiúsculas, e se são masculinos.
  static const Map<String, bool> _knownNouns = {
    'ong': false,
    'instituto': true,
    'instituição': false,
    'instituicao': false,
    'associação': false,
    'associacao': false,
    'projeto': true,
  };

  // Analisa o nome da ONG; o substantivo informado (feminino) é usado quando o nome não traz um próprio.
  factory NgoNameWords.from(String ngoName, {String noun = 'ONG'}) {
    final name = ngoName.trim();
    final firstWord = name.split(RegExp(r'\s+')).first.toLowerCase();
    final isMasculine = _knownNouns[firstWord];

    if (isMasculine != null) {
      return NgoNameWords._(phrase: name, isMasculine: isMasculine);
    }
    return NgoNameWords._(phrase: '$noun $name', isMasculine: false);
  }

  // Terminação de adjetivos e particípios que concordam com a ONG (ex.: "aprovad" + "a").
  String get ending => isMasculine ? 'o' : 'a';

  // Referência com artigo no meio da frase: "a ONG Miau de Rua", "o Instituto Patinhas".
  String get withArticle => '${isMasculine ? 'o' : 'a'} $phrase';

  // Referência com artigo no início da frase: "A ONG Miau de Rua", "O Instituto Patinhas".
  String get startOfSentence => '${isMasculine ? 'O' : 'A'} $phrase';

  // Referência com a preposição "de": "da ONG Miau de Rua", "do Instituto Patinhas".
  String get withDe => '${isMasculine ? 'do' : 'da'} $phrase';

  // Referência com a preposição "por": "pela ONG Miau de Rua", "pelo Instituto Patinhas".
  String get withPor => '${isMasculine ? 'pelo' : 'pela'} $phrase';
}
