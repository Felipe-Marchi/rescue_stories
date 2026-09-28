import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/adoption_request_model.dart';
import '../models/enums/adoption_status.dart';
import 'animal_service.dart';
import 'ngo_service.dart';
import 'notification_service.dart';

// Gerencia a comunicação entre o aplicativo e o banco de dados Firestore para a entidade solicitações de adoção.
class AdoptionService {
  final CollectionReference _requestsCollection =
      FirebaseFirestore.instance.collection('adoption_requests');
  final AnimalService _animalService = AnimalService();
  final NgoService _ngoService = NgoService();
  final NotificationService _notificationService = NotificationService();

  // Registra uma nova solicitação de intenção de adoção na coleção do banco de dados.
  Future<void> createAdoptionRequest(AdoptionRequestModel request) async {
    await _requestsCollection.add(request.toMap());
  }

  // Recupera a lista de solicitações de adoção vinculadas a uma ONG específica em tempo real.
  Stream<List<AdoptionRequestModel>> getRequestsByNgo(String ngoId) {
    return _requestsCollection
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AdoptionRequestModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Recupera em tempo real a quantidade de solicitações pendentes de uma ONG.
  Stream<int> streamPendingCountByNgo(String ngoId) {
    return _requestsCollection
        .where('ngoId', isEqualTo: ngoId)
        .where('status', isEqualTo: AdoptionStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Recupera a quantidade de solicitações pendentes de uma ONG criadas há mais tempo que o prazo informado.
  Future<int> countPendingOlderThan(String ngoId, Duration threshold) async {
    final snapshot = await _requestsCollection
        .where('ngoId', isEqualTo: ngoId)
        .where('status', isEqualTo: AdoptionStatus.pending.name)
        .get();

    final limit = DateTime.now().subtract(threshold);
    return snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return AdoptionRequestModel.fromMap(doc.id, data).createdAt.isBefore(limit);
    }).length;
  }

  // Recupera as solicitações de adoção aprovadas de um adotante.
  Future<List<AdoptionRequestModel>> getApprovedRequestsByAdopter(String adopterId) async {
    final snapshot = await _requestsCollection
        .where('adopterId', isEqualTo: adopterId)
        .where('status', isEqualTo: AdoptionStatus.approved.name)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return AdoptionRequestModel.fromMap(doc.id, data);
    }).toList();
  }

  // Atualiza a situação do pedido de adoção no banco de dados, registrando o momento da decisão,
  // e avisa o adotante sobre a decisão da ONG.
  Future<void> updateRequestStatus(AdoptionRequestModel request, AdoptionStatus status) async {
    await _requestsCollection.doc(request.id).update({
      'status': status.name,
      'decidedAt': FieldValue.serverTimestamp(),
    });

    unawaited(_notifyAdopterAboutDecision(request, status));
  }

  // Avisa o adotante sobre a aprovação ou a recusa da solicitação, sem propagar falhas ao fluxo principal.
  // Reutilizável por outros métodos que alterem a situação da solicitação (ex.: aprovação em lote).
  Future<void> _notifyAdopterAboutDecision(AdoptionRequestModel request, AdoptionStatus status) async {
    try {
      final animal = await _animalService.getAnimalById(request.animalId);
      if (animal == null) return;

      if (status == AdoptionStatus.approved) {
        final ngo = await _ngoService.getNgoById(request.ngoId);
        await _notificationService.notifyAdoptionApproved(
          adopterId: request.adopterId,
          ngoName: (ngo != null && ngo.name.isNotEmpty) ? ngo.name : 'responsável',
          animal: animal,
        );
      } else if (status == AdoptionStatus.rejected) {
        await _notificationService.notifyAdoptionRejected(
          adopterId: request.adopterId,
          animal: animal,
        );
      }
    } catch (e) {
      debugPrint('Falha ao notificar o adotante sobre a decisão da solicitação: $e');
    }
  }
}