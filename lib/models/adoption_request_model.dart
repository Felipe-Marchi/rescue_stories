import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums/adoption_status.dart';

// Representa os dados de uma solicitação de intenção de adoção realizada por um usuário.
class AdoptionRequestModel {
  final String id;
  final String animalId;
  final String adopterId;
  final String ngoId;
  final String status;
  final DateTime createdAt;

  // Inicializa uma instância da classe com os dados obrigatórios da intenção de adoção.
  AdoptionRequestModel({
    required this.id,
    required this.animalId,
    required this.adopterId,
    required this.ngoId,
    required this.status,
    required this.createdAt,
  });

  // Converte a instância da classe em um mapa de dados para gravação no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'animalId': animalId,
      'adopterId': adopterId,
      'ngoId': ngoId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Converte o mapa de dados recebido do Firestore em uma instância da classe AdoptionRequestModel.
  factory AdoptionRequestModel.fromMap(String id, Map<String, dynamic> data) {
    return AdoptionRequestModel(
      id: id,
      animalId: data['animalId'] ?? '',
      adopterId: data['adopterId'] ?? '',
      ngoId: data['ngoId'] ?? '',
      status: data['status'] ?? AdoptionStatus.pending.name,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}