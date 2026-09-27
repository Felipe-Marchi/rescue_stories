// Representa os dados institucionais de uma organização de resgate.
class NgoModel {
  final String id;
  final String name;
  final String document;
  final String email;
  final String phone;
  final String address;
  final String ownerId;

  // Inicializa os dados da organização
  NgoModel({
    required this.id,
    required this.name,
    required this.document,
    required this.email,
    required this.phone,
    required this.address,
    required this.ownerId,
  });

  // Converte a instância da classe em um mapa de dados para gravação no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'document': document,
      'email': email,
      'phone': phone,
      'address': address,
      'ownerId': ownerId,
    };
  }

  // Converte o mapa de dados recebido do Firestore em uma instância da classe NgoModel.
  factory NgoModel.fromMap(String id, Map<String, dynamic> data) {
    return NgoModel(
      id: id,
      name: data['name'] ?? '',
      document: data['document'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      ownerId: data['ownerId'] ?? '',
    );
  }
}
