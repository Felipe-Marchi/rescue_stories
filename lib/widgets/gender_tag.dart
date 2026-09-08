import 'package:flutter/material.dart';

// Renderiza uma tag visual padronizada para indicação do sexo do animal.
class GenderTag extends StatelessWidget {
  final String gender;
  final bool isLarge;

  // Inicializa o componente exigindo o sexo informado e aceitando variação de tamanho.
  const GenderTag({
    super.key,
    required this.gender,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isFemale = gender == 'Fêmea';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12.0 : 10.0,
        vertical: isLarge ? 6.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: isFemale ? Colors.pink.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(isLarge ? 16.0 : 12.0),
      ),
      child: Text(
        gender,
        style: TextStyle(
          fontSize: isLarge ? 14.0 : 12.0,
          fontWeight: FontWeight.bold,
          color: isFemale ? Colors.pink.shade700 : Colors.blue.shade700,
        ),
      ),
    );
  }
}