import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Gerencia a comunicação de autenticação e controle de sessão de usuários no Firebase.
class AuthService {
  // Instancia a referência para o serviço de autenticação nativo do Firebase.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Retorna a instancia do usuario atualmente autenticado de forma sincrona.
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    // Cria a identidade no Firebase Auth
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Define o status inicial baseado na funcao escolhida
    final status = role == 'ngo_rep' ? 'pending_ngo' : 'active';

    // Grava o documento de perfil na colecao 'users'
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // Autentica um usuário existente no sistema validando as credenciais informadas.
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Encerra a sessão do usuário atualmente autenticado no aplicativo.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}