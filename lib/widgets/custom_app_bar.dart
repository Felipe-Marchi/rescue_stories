import 'package:flutter/material.dart';

// Renderiza a barra superior padronizada do aplicativo com suporte a hierarquia visual.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isMainPage;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  // Inicializa o componente definindo, por padrao, que nao se trata da tela principal.
  const CustomAppBar({
    super.key,
    required this.title,
    this.isMainPage = false,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      // Define a cor da seta de voltar nativa.
      iconTheme: const IconThemeData(color: Colors.black87),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Exibe o icone da marca apenas se for a tela principal.
          if (isMainPage) ...[
            const Icon(
              Icons.pets,
              color: Colors.green,
              size: 28.0,
            ),
            const SizedBox(width: 8.0),
          ],
          // Ajusta a tipografia dinamicamente com base na hierarquia da tela.
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              // Usa negrito extra-pesado para a Home, e semi-negrito para telas internas.
              fontWeight: isMainPage ? FontWeight.w800 : FontWeight.w600,
              // Usa fonte tamanho 22 para a Home, e 18 para telas internas.
              fontSize: isMainPage ? 22.0 : 18.0,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  // Define a altura padrao reservada para a barra de navegacao superior.
  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}