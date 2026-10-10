import 'package:cloud_firestore/cloud_firestore.dart';

// Representa uma publicação individual da linha do tempo/história de um animal.
class PetTimelinePostModel {
  final String id;
  final String animalId;
  final String authorId;
  final String authorRole;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;

  // Inicializa a instância da postagem com os identificadores e dados obrigatórios.
  PetTimelinePostModel({
    required this.id,
    required this.animalId,
    required this.authorId,
    required this.authorRole,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
  });

  // Converte a instância em um mapa de dados para gravação no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'animalId': animalId,
      'authorId': authorId,
      'authorRole': authorRole,
      'imageUrl': imageUrl,
      'caption': caption,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Converte o mapa de dados recebido do Firestore em um PetTimelinePostModel.
  factory PetTimelinePostModel.fromMap(String id, Map<String, dynamic> data) {
    return PetTimelinePostModel(
      id: id,
      animalId: data['animalId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorRole: data['authorRole'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}