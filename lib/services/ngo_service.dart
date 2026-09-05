import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngo_model.dart';

// Gerencia a comunicação entre o aplicativo e o banco de dados Firestore para a entidade organização (ONG).
class NgoService {
  // Instancia a referência para a coleção de organizações no banco de dados.
  final CollectionReference _ngosCollection = FirebaseFirestore.instance.collection('ngos');

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

  // Recupera a lista de organizações armazenadas no banco de dados em tempo real.
  Stream<List<NgoModel>> getNgos() {
    return _ngosCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NgoModel(
          id: doc.id,
          name: data['name'] ?? '',
          document: data['document'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          ownerId: data['ownerId'] ?? '',
        );
      }).toList();
    });
  }
}