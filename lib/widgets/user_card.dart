import 'package:flutter/material.dart';
import '../models/user_model.dart';

// Renderiza as informações de um usuário em um contêiner visual unificado para perfil ou gestão.
class UserCard extends StatelessWidget {
  final UserModel user;
  final bool showRoleBadge;
  final bool showStatusTag;
  final VoidCallback? onTap;

  // Inicializa o componente aceitando o objeto UserModel e flags para exibição de badge e status.
  const UserCard({
    super.key,
    required this.user,
    this.showRoleBadge = false,
    this.showStatusTag = false,
    this.onTap,
  });

  Widget _buildRoleBadge() {
    String label = 'Adotante';

    if (user.isAdmin) {
      label = 'Admin';
    } else if (user.isNgoRep) {
      label = 'ONG';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildStatusTag() {
    String label = 'Ativo';
    Color color = Colors.green.shade700;

    if (user.isUnderReview) {
      label = 'Em Análise';
      color = Colors.amber.shade800;
    } else if (user.status == 'rejected') {
      label = 'Rejeitado';
      color = Colors.red.shade700;
    }

    return Text(
      label,
      style: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.0,
            backgroundColor: Colors.grey.shade100,
            child: Icon(
              user.isAdmin
                  ? Icons.admin_panel_settings
                  : (user.isNgoRep ? Icons.business : Icons.person),
              color: Colors.grey.shade700,
              size: 28.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showRoleBadge) ...[
                      const SizedBox(width: 8.0),
                      _buildRoleBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showStatusTag) _buildStatusTag(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}