import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

// Gerencia a transferência de arquivos físicos para o servidor de armazenamento em nuvem.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Realiza o upload de um arquivo de imagem e retorna a URL de acesso público.
  Future<String> uploadAnimalImage(File imageFile, String fileName) async {
    final reference = _storage.ref().child('animals').child(fileName);
    final uploadTask = await reference.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
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