import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';
import '../utils/network.dart';
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
      final animal = AnimalModel.fromMap(doc.id, data);

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
        return AnimalModel.fromMap(doc.id, data);
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
        return AnimalModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Gera localmente um novo identificador de documento para um animal, sem acessar a rede.
  String newAnimalId() => _animalsCollection.doc().id;

  // Registra as informações de um animal na coleção usando o identificador já gerado,
  // de modo que novas tentativas sobrescrevam o mesmo documento em vez de duplicá-lo.
  Future<void> addAnimal(AnimalModel animal) async {
    await _animalsCollection.doc(animal.id).set(animal.toMap()).timeout(networkTimeout);
  }

  // Atualiza as informações de um animal existente no banco de dados e atualiza o cache em memória.
  Future<void> updateAnimal(AnimalModel animal, {String? oldImageUrl}) async {
    // Preserva o vínculo original com a ONG, que não é alterado na edição.
    await _animalsCollection
        .doc(animal.id)
        .update(animal.toMap()..remove('ngoId'))
        .timeout(networkTimeout);

    _animalCache[animal.id] = animal;

    // Remove a imagem antiga somente após a gravação, para não deixar o registro apontando para um arquivo excluído.
    if (oldImageUrl != null && oldImageUrl.isNotEmpty && oldImageUrl != animal.imageUrl) {
      await _storageService.deleteImageByUrl(oldImageUrl);
    }
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