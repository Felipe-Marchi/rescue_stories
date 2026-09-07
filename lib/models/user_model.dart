import 'enums/user_role.dart';
import 'enums/user_status.dart';

// Representa as informações de perfil e nível de acesso de um usuário no sistema.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? ngoId;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.ngoId,
  });

  // Converte dados brutos do mapa de dados em uma instância da classe UserModel.
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? UserRole.adopter.name,
      status: data['status'] ?? UserStatus.active.name,
      ngoId: data['ngoId'] as String?,
    );
  }

  // Identifica se o usuário possui papel de administrador no sistema.
  bool get isAdmin => role == UserRole.admin.name;

  // Identifica se o usuário possui papel de representante de uma ONG.
  bool get isNgoRep => role == UserRole.ngoRep.name;

  // Identifica se o usuário possui papel de adotante.
  bool get isAdopter => role == UserRole.adopter.name;

  // Identifica se o status da conta do usuário está ativo e liberado.
  bool get isActive => status == UserStatus.active.name;

  // Identifica se a conta do usuário está sob análise da administração.
  bool get isUnderReview => status == UserStatus.underReview.name;
}