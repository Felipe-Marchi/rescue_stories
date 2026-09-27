import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/network.dart';

// Gerencia a transferência de arquivos físicos para o servidor de armazenamento em nuvem.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Tempo máximo de espera pelo envio completo de uma imagem, mesmo com a conexão ativa.
  static const Duration _uploadTimeout = Duration(seconds: 60);

  // Limita as novas tentativas automáticas do Storage para que a falta de conexão gere erro rapidamente.
  StorageService() {
    _storage.setMaxUploadRetryTime(networkTimeout);
    _storage.setMaxOperationRetryTime(networkTimeout);
  }

  // Realiza o upload de um arquivo de imagem e retorna a URL de acesso público.
  Future<String> uploadAnimalImage(File imageFile, String fileName) async {
    final reference = _storage.ref().child('animals').child(fileName);
    final uploadTask = reference.putFile(imageFile);

    try {
      final snapshot = await uploadTask.timeout(_uploadTimeout);
      return await snapshot.ref.getDownloadURL().timeout(networkTimeout);
    } on TimeoutException {
      await uploadTask.cancel();
      rethrow;
    }
  }

  // Exclui um arquivo de imagem do Firebase Storage a partir da sua URL pública.
  Future<void> deleteImageByUrl(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final reference = _storage.refFromURL(imageUrl);
      await reference.delete();
    } catch (e) {
      // Silenciosamente ignora caso a imagem já não exista no servidor de armazenamento.
    }
  }
}
