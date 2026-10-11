import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_timeline_post_model.dart';
import 'storage_service.dart';

// Gerencia a gravação, leitura reativa, atualização e exclusão de postagens na subcoleção 'timeline' de cada animal.
class PetTimelineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Retorna a referência para a subcoleção 'timeline' de um animal específico.
  CollectionReference _getTimelineCollection(String animalId) {
    return _firestore.collection('animals').doc(animalId).collection('timeline');
  }

  // Grava uma nova atualização de história/foto na subcoleção do animal.
  Future<void> addPost(PetTimelinePostModel post) async {
    await _getTimelineCollection(post.animalId).add(post.toMap());
  }

  // Atualiza uma postagem existente na linha do tempo e remove a foto antiga do Storage se alterada.
  Future<void> updatePost(PetTimelinePostModel post, {String? oldImageUrl}) async {
    if (oldImageUrl != null && oldImageUrl.isNotEmpty && oldImageUrl != post.imageUrl) {
      await _storageService.deleteImageByUrl(oldImageUrl);
    }
    await _getTimelineCollection(post.animalId).doc(post.id).update(post.toMap());
  }

  // Recupera em tempo real a lista de postagens da linha do tempo do animal em ordem cronológica.
  Stream<List<PetTimelinePostModel>> getTimelineByAnimal(String animalId) {
    return _getTimelineCollection(animalId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PetTimelinePostModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Exclui a postagem da subcoleção e remove sua imagem do Firebase Storage, caso exista.
  Future<void> deletePost(String animalId, String postId, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await _storageService.deleteImageByUrl(imageUrl);
    }
    await _getTimelineCollection(animalId).doc(postId).delete();
  }
}