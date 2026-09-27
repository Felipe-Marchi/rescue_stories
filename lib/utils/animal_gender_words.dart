// Reúne as palavras que variam conforme o sexo do animal para manter a concordância dos textos do aplicativo.
class AnimalGenderWords {
  final String article;
  final String contraction;
  final String pronoun;
  final String adoptVerb;
  final String subject;

  const AnimalGenderWords({
    required this.article,
    required this.contraction,
    required this.pronoun,
    required this.adoptVerb,
    required this.subject,
  });

  // Seleciona as palavras femininas para 'Fêmea' e masculinas para os demais casos.
  factory AnimalGenderWords.fromGender(String gender) {
    if (gender == 'Fêmea') {
      return const AnimalGenderWords(
        article: 'a',
        contraction: 'da',
        pronoun: 'por ela',
        adoptVerb: 'adotá-la',
        subject: 'ela',
      );
    }
    return const AnimalGenderWords(
      article: 'o',
      contraction: 'do',
      pronoun: 'por ele',
      adoptVerb: 'adotá-lo',
      subject: 'ele',
    );
  }
}
