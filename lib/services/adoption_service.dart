import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/adoption_request_model.dart';
import '../models/enums/adoption_status.dart';

// Gerencia a comunicação entre o aplicativo e o banco de dados Firestore para a entidade solicitações de adoção.
class AdoptionService {
  final CollectionReference _requestsCollection =
      FirebaseFirestore.instance.collection('adoption_requests');

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

  // Atualiza a situação do pedido de adoção no banco de dados.
  Future<void> updateRequestStatus(String requestId, AdoptionStatus status) async {
    await _requestsCollection.doc(requestId).update({
      'status': status.name,
    });
  }
}