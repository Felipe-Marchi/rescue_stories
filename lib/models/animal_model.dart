import 'enums/animal_status.dart';

// Representa as informações de um animal cadastrado no sistema.
class AnimalModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String ngoId;
  final String gender;
  final String status;
  final String? adopterId;

  // Inicializa uma instância da classe com os dados obrigatórios e opcionais do animal.
  AnimalModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.ngoId,
    required this.gender,
    this.status = 'available',
    this.adopterId,
  });

  // Converte a instância da classe em um mapa de dados para gravação no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'ngoId': ngoId,
      'gender': gender,
      'status': status,
      'adopterId': adopterId,
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
      status: data['status'] ?? AnimalStatus.available.name,
      adopterId: data['adopterId'] as String?,
    );
  }

  // Identifica se o animal está disponível para adoção.
  bool get isAvailable => status == AnimalStatus.available.name;

  // Identifica se o animal já foi adotado.
  bool get isAdopted => status == AnimalStatus.adopted.name;
}