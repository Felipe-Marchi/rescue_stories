import 'ngo_model.dart';
import 'user_model.dart';

// Representa a solicitação de cadastro de uma organização vinculando os dados do usuário e da ONG.
class NgoRequestModel {
  final UserModel user;
  final NgoModel ngo;

  NgoRequestModel({
    required this.user,
    required this.ngo,
  });
}