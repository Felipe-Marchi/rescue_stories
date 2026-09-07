import 'ngo_model.dart';

// Representa a solicitação de cadastro de uma organização pendente de avaliação.
class NgoRequestModel {
  final String userId;
  final String userName;
  final String userEmail;
  final String userStatus;
  final NgoModel ngo;

  NgoRequestModel({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userStatus,
    required this.ngo,
  });
}