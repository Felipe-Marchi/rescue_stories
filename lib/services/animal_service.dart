import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';
import 'storage_service.dart';

// Gerencia a comunicação entre o aplicativo e o banco de dados Firestore para a entidade animal.
class AnimalService {
  // Instancia a referência para a coleção de animais no banco de dados.
  final CollectionReference _animalsCollection = FirebaseFirestore.instance.collection('animals');
  final StorageService _storageService = StorageService();

  // Cache estático em memória para armazenar objetos AnimalModel e evitar buscas repetidas.
  static final Map<String, AnimalModel> _animalCache = {};

  // Recupera um animal específico pelo seu identificador único.
  Future<AnimalModel?> getAnimalById(String animalId) async {
    if (animalId.isEmpty) return null;

    if (_animalCache.containsKey(animalId)) {
      return _animalCache[animalId];
    }

    try {
      final doc = await _animalsCollection.doc(animalId).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data() as Map<String, dynamic>;
      final animal = AnimalModel(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        ngoId: data['ngoId'] ?? '',
        gender: data['gender'] ?? 'Macho',
      );

      _animalCache[animalId] = animal;
      return animal;
    } catch (e) {
      return null;
    }
  }

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

  // Recupera a lista de animais vinculados a uma ONG específica em tempo real.
  Stream<List<AnimalModel>> getAnimalsByNgo(String ngoId) {
    return _animalsCollection
        .where('ngoId', isEqualTo: ngoId)
        .snapshots()
        .map((snapshot) {
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

  // Atualiza as informações de um animal existente no banco de dados e atualiza o cache em memória.
  Future<void> updateAnimal(AnimalModel animal, {String? oldImageUrl}) async {
    if (oldImageUrl != null && oldImageUrl.isNotEmpty && oldImageUrl != animal.imageUrl) {
      await _storageService.deleteImageByUrl(oldImageUrl);
    }

    await _animalsCollection.doc(animal.id).update({
      'name': animal.name,
      'description': animal.description,
      'imageUrl': animal.imageUrl,
      'gender': animal.gender,
    });

    _animalCache[animal.id] = animal;
  }

  // Exclui o registro do animal do banco de dados, remove sua foto do Storage e limpa o cache.
  Future<void> deleteAnimal(String animalId, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _storageService.deleteImageByUrl(imageUrl);
    }
    await _animalsCollection.doc(animalId).delete();
    _animalCache.remove(animalId);
  }
}