// Representa as informações de um animal disponível para resgate no sistema.
class AnimalModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String ngoId;
  final String gender;

  // Inicializa uma instância da classe com os dados obrigatórios do animal.
  AnimalModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.ngoId,
    required this.gender,
  });

  // Converte a instância da classe em um mapa de dados para gravação no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'ngoId': ngoId,
      'gender': gender,
    };
  }

  // Converte o mapa de dados recebido do Firestore em uma instância da classe AnimalModel.
  factory AnimalModel.fromMap(String id, Map<String, dynamic> data) {
    return AnimalModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ngoId: data['ngoId'] ?? '',
      gender: data['gender'] ?? 'Macho',
    );
  }
}
