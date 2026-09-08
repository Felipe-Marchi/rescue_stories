import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';

// Gerencia a comunicação entre o aplicativo e o banco de dados Firestore para a entidade animal.
class AnimalService {
  // Instancia a referência para a coleção de animais no banco de dados.
  final CollectionReference _animalsCollection = FirebaseFirestore.instance.collection('animals');

  // Recupera a lista de animais armazenada no banco de dados em tempo real.
  Stream<List<AnimalModel>> getAnimals() {
    return _animalsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AnimalModel(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          ngoId: data['ngoId'] ?? '',
          gender: data['gender'] ?? 'Macho',
        );
      }).toList();
    });
  }

  // Registra as informações de um animal na coleção do banco de dados.
  Future<void> addAnimal(AnimalModel animal) async {
    await _animalsCollection.add({
      'name': animal.name,
      'description': animal.description,
      'imageUrl': animal.imageUrl,
      'ngoId': animal.ngoId,
      'gender': animal.gender,
    });
  }
}