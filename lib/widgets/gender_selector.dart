import 'package:flutter/material.dart';

// Renderiza o seletor de opções para a escolha do sexo do animal no formulário.
class GenderSelector extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onGenderSelected;

  // Inicializa o componente exigindo o valor selecionado e a função de notificação de alteração.
  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sexo do Animal',
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Macho')),
                selected: selectedGender == 'Macho',
                selectedColor: Colors.green.shade100,
                onSelected: (selected) {
                  if (selected) {
                    onGenderSelected('Macho');
                  }
                },
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Fêmea')),
                selected: selectedGender == 'Fêmea',
                selectedColor: Colors.green.shade100,
                onSelected: (selected) {
                  if (selected) {
                    onGenderSelected('Fêmea');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}