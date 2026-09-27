import 'package:flutter/material.dart';

// Renderiza um contador discreto em formato de pílula verde, usado ao lado de itens de menu e abas.
class CountPill extends StatelessWidget {
  final int count;

  // Inicializa o componente exigindo a quantidade exibida.
  const CountPill({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }
}
