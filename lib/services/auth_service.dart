import 'package:firebase_auth/firebase_auth.dart';

// Gerencia a comunicação de autenticação e controle de sessão de usuários no Firebase.
class AuthService {
  // Instancia a referência para o serviço de autenticação nativo do Firebase.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Monitora o estado de autenticação em tempo real, retornando o usuário logado ou nulo.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Realiza o cadastro de um novo usuário no sistema utilizando e-mail e senha.
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
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