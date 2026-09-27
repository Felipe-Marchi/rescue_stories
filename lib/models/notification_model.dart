import 'package:cloud_firestore/cloud_firestore.dart';

// Representa uma notificação destinada a um usuário e exibida na central de notificações.
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String relatedId;
  final bool read;
  final DateTime createdAt;

  // Inicializa uma instância da classe com os dados obrigatórios da notificação.
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.relatedId,
    required this.read,
    required this.createdAt,
  });

  // Converte a instância em um mapa para gravação no Firestore, usando o horário do servidor na criação.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'read': read,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Converte o mapa de dados recebido do Firestore em uma instância da classe NotificationModel.
  // Enquanto o horário do servidor ainda não foi confirmado (escrita pendente), usa o horário atual.
  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      relatedId: data['relatedId'] ?? '',
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
