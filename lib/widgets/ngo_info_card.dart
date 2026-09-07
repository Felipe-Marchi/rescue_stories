import 'package:flutter/material.dart';
import '../models/ngo_model.dart';
import '../services/ngo_service.dart';

// Renderiza o cartão de informações institucionais e de contato da ONG com base no ngoId.
class NgoInfoCard extends StatelessWidget {
  final String ngoId;
  final NgoService _ngoService = NgoService();

  // Inicializa o componente recebendo o identificador da ONG.
  NgoInfoCard({
    super.key,
    required this.ngoId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NgoModel?>(
      future: _ngoService.getNgoById(ngoId),
      builder: (context, snapshot) {
        final ngo = snapshot.data;
        final ngoName = ngo != null && ngo.name.isNotEmpty
            ? ngo.name
            : (snapshot.connectionState == ConnectionState.waiting
                ? 'Carregando...'
                : 'ONG não informada');

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.business, color: Colors.green, size: 28.0),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instituição Responsável',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      ngoName,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (ngo != null && ngo.phone.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        'Contato: ${ngo.phone}',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}