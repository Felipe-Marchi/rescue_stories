import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_model.dart';
import '../models/dtos/ngo_request_model.dart';
import '../models/user_model.dart';
import '../models/enums/user_role.dart';
import '../models/enums/user_status.dart';

// Gerencia a comunicação entre o aplicativo e o banco de dados Firestore para a entidade organização (ONG).
class NgoService {
  // Instancia a referência para a coleção de organizações no banco de dados.
  final CollectionReference _ngosCollection = FirebaseFirestore.instance.collection('ngos');

  // Cache estático em memória para armazenar os objetos NgoModel completos e evitar requisições repetidas ao Firestore.
  static final Map<String, NgoModel> _ngoCache = {};

  // Registra as informações institucionais de uma organização.
  Future<String> addNgo(NgoModel ngo) async {
    final docRef = await _ngosCollection.add({
      'name': ngo.name,
      'document': ngo.document,
      'email': ngo.email,
      'phone': ngo.phone,
      'address': ngo.address,
      'ownerId': ngo.ownerId,
    });

    return docRef.id;
  }

  // Recupera uma organização específica pelo seu identificador com suporte a cache.
  Future<NgoModel?> getNgoById(String ngoId) async {
    if (ngoId.isEmpty) return null;

    if (_ngoCache.containsKey(ngoId)) {
      return _ngoCache[ngoId];
    }

    try {
      final doc = await _ngosCollection.doc(ngoId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final ngo = NgoModel(
        id: doc.id,
        name: data['name'] ?? '',
        document: data['document'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        address: data['address'] ?? '',
        ownerId: data['ownerId'] ?? '',
      );

      _ngoCache[ngoId] = ngo;
      return ngo;
    } catch (e) {
      return null;
    }
  }

  // Recupera a lista de solicitações de ONGs pendentes de análise.
  Stream<List<NgoRequestModel>> getPendingRequests() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: UserRole.ngoRep.name)
        .where('status', isEqualTo: UserStatus.underReview.name)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<NgoRequestModel> requests = [];
      for (final doc in snapshot.docs) {
        final userData = doc.data();
        final userModel = UserModel.fromMap(doc.id, userData);

        if (userModel.ngoId != null && userModel.ngoId!.isNotEmpty) {
          final ngo = await getNgoById(userModel.ngoId!);
          if (ngo != null) {
            requests.add(
              NgoRequestModel(
                user: userModel,
                ngo: ngo,
              ),
            );
          }
        }
      }
      return requests;
    });
  }

  // Recupera a lista de ONGs aprovadas e ativas no sistema.
  Stream<List<NgoRequestModel>> getApprovedRequests() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: UserRole.ngoRep.name)
        .where('status', isEqualTo: UserStatus.active.name)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<NgoRequestModel> requests = [];
      for (final doc in snapshot.docs) {
        final userData = doc.data();
        final userModel = UserModel.fromMap(doc.id, userData);

        if (userModel.ngoId != null && userModel.ngoId!.isNotEmpty) {
          final ngo = await getNgoById(userModel.ngoId!);
          if (ngo != null) {
            requests.add(
              NgoRequestModel(
                user: userModel,
                ngo: ngo,
              ),
            );
          }
        }
      }
      return requests;
    });
  }

  // Recupera a lista de organizações armazenadas no banco de dados em tempo real.
  Stream<List<NgoModel>> getNgos() {
    return _ngosCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final ngo = NgoModel(
          id: doc.id,
          name: data['name'] ?? '',
          document: data['document'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          ownerId: data['ownerId'] ?? '',
        );

        _ngoCache[doc.id] = ngo;
        return ngo;
      }).toList();
    });
  }
}