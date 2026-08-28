import 'package:flutter/material.dart';

// Renderiza uma imagem a partir de uma URL remota com tratamento automático de falhas e ausência de dados.
class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final BoxFit fit;

  // Inicializa o componente exigindo a URL e a altura, com preenchimento padrão de corte.
  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    required this.height,
    this.fit = BoxFit.cover,
  });

  // Constrói um componente visual padronizado para substituir imagens ausentes ou quebradas.
  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 48.0,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Não foi possível carregar a imagem',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Intercepta URLs vazias antes de acionar o motor de renderização de rede.
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // Tenta carregar a imagem real, acionando o fallback em caso de erro (ex: link quebrado).
    return Image.network(
      imageUrl,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }
}