// Representa os dados institucionais de uma organização de resgate.
class NgoModel {
  final String id;
  final String name;
  final String document;
  final String email;
  final String phone;
  final String address;

  // Inicializa os dados da organização
  NgoModel({
    required this.id,
    required this.name,
    required this.document,
    required this.email,
    required this.phone,
    required this.address,
  });
}