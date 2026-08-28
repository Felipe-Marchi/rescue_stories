import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

// Gerencia a transferencia de arquivos fisicos para o servidor de armazenamento em nuvem.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Realiza o upload de um arquivo de imagem e retorna a URL de acesso publico.
  Future<String> uploadAnimalImage(File imageFile, String fileName) async {
    final reference = _storage.ref().child('animals').child(fileName);
    final uploadTask = await reference.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }
}