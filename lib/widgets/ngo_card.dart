import 'package:flutter/material.dart';
import '../models/ngo_model.dart';
import '../services/ngo_service.dart';

// Renderiza o cartão de informações da ONG com suporte a modo compacto e detalhado.
class NgoCard extends StatelessWidget {
  final String? ngoId;
  final NgoModel? ngo;
  final bool isCompact;
  final String? title;
  final bool showPhone;
  final VoidCallback? onTap;

  final NgoService _ngoService = NgoService();

  // Inicializa o componente aceitando opcionalmente o ngoId, o objeto NgoModel, título, visibilidade de telefone e ação ao clicar.
  NgoCard({
    super.key,
    this.ngoId,
    this.ngo,
    this.isCompact = false,
    this.title = 'Instituição Responsável',
    this.showPhone = true,
    this.onTap,
  });

  Widget _buildContent(NgoModel? ngoData, {bool isLoading = false}) {
    final ngoName = ngoData != null && ngoData.name.isNotEmpty
        ? ngoData.name
        : (isLoading ? 'Carregando...' : 'ONG não vinculada');

    if (isCompact) {
      return Row(
        children: [
          const Icon(Icons.business, size: 14.0, color: Colors.green),
          const SizedBox(width: 4.0),
          Expanded(
            child: Text(
              ngoName,
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    Widget content = Container(
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
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                ],
                Text(
                  ngoName,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (ngoData != null && ngoData.document.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    'CNPJ: ${ngoData.document}',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                if (showPhone && ngoData != null && ngoData.phone.isNotEmpty) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    'Contato: ${ngoData.phone}',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8.0),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ],
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    if (ngo != null) {
      return _buildContent(ngo);
    }

    if (ngoId != null && ngoId!.isNotEmpty) {
      return FutureBuilder<NgoModel?>(
        future: _ngoService.getNgoById(ngoId!),
        builder: (context, snapshot) {
          final fetchedNgo = snapshot.data;
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          return _buildContent(fetchedNgo, isLoading: isLoading);
        },
      );
    }

    return _buildContent(null);
  }
}