// Representa as informações de um animal disponível para resgate no sistema.
class AnimalModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String ngoId;
  final String ngoName;

  // Inicializa uma instância da classe com os dados obrigatórios do animal.
  AnimalModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.ngoId,
    required this.ngoName,
  });
}