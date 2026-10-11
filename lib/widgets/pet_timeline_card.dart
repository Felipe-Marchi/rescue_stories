import 'package:flutter/material.dart';
import '../models/pet_timeline_post_model.dart';
import '../models/enums/user_role.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';
import 'custom_network_image.dart';

// Renderiza o cartão de uma publicação individual da linha do tempo/história do animal, com opções de gestão para o autor.
class PetTimelineCard extends StatelessWidget {
  final PetTimelinePostModel post;
  final String animalName;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  final AuthService _authService = AuthService();

  // Inicializa o componente aceitando a postagem, o nome do animal, a autorização do autor e os callbacks de gestão.
  PetTimelineCard({
    super.key,
    required this.post,
    required this.animalName,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });

  // Exibe o painel deslizante inferior com as opções de editar e excluir para o autor.
  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Text(
                    'História de $animalName',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Divider(),
                if (onEdit != null)
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.green),
                    title: const Text(
                      'Editar',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onEdit!();
                    },
                  ),
                if (onDelete != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text(
                      'Excluir',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16.0),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmDelete(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Exibe o diálogo de confirmação para a exclusão da publicação.
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Publicação'),
          content: const Text('Tem certeza que deseja excluir esta foto da história do pet?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                if (onDelete != null) onDelete!();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNgoAuthor = post.authorRole == UserRole.ngoRep.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: FutureBuilder<UserModel?>(
        future: _authService.getUserProfile(post.authorId),
        builder: (context, authorSnapshot) {
          final authorModel = authorSnapshot.data;
          final authorName = authorModel?.name ?? 'Autor';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18.0,
                      backgroundColor: isNgoAuthor ? Colors.green.shade100 : Colors.blue.shade100,
                      child: Icon(
                        isNgoAuthor ? Icons.business : Icons.favorite,
                        size: 18.0,
                        color: isNgoAuthor ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            isNgoAuthor ? 'Instituição Responsável' : 'Novo Lar / Adotante',
                            style: TextStyle(
                              fontSize: 11.0,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatDate(post.createdAt),
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(width: 4.0),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade700,
                            size: 20.0,
                          ),
                          onPressed: () => _showOptionsBottomSheet(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              CustomNetworkImage(
                imageUrl: post.imageUrl,
                height: 220.0,
              ),
              if (post.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    post.caption,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade800,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}