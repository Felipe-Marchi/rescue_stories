import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_status.dart';
import '../models/user_role.dart';

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
    final status = role == UserRole.ngoRep.name ? UserStatus.pendingSetup.name : UserStatus.active.name;

    // Grava o documento de perfil na colecao 'users'
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'ngoId': null,
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

  // Atualiza o documento do usuario com o identificador da instituicao e altera o status de acesso.
  Future<void> linkUserToNgo(String userId, String ngoId) async {
    await _firestore.collection('users').doc(userId).update({
      'ngoId': ngoId,
      'status': UserStatus.underReview.name,
    });
  }

  // Recupera as informações do perfil do usuário como objeto UserModel.
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  // Recupera o papel de acesso do usuario no banco de dados.
  Future<String?> getUserRole(String userId) async {
    final userModel = await getUserProfile(userId);
    return userModel?.role;
  }

  // Atualiza o status do usuario no banco de dados.
  Future<void> updateUserStatus(String userId, String status) async {
    await _firestore.collection('users').doc(userId).update({
      'status': status,
    });
  }
}