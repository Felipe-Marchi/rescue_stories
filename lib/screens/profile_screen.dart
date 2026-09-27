import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/ngo_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/user_card.dart';
import 'ngo_management_screen.dart';
import 'user_management_screen.dart';
import 'animal_management_screen.dart';
import 'animal_form_screen.dart';
import 'ngo_form_screen.dart';
import 'adoption_management_screen.dart';
import 'profile_form_screen.dart';

// Renderiza a interface de perfil do usuário autenticado com opções de gerenciamento de conta.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// Gerencia o carregamento do perfil e o recarrega após a edição dos dados do usuário.
class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();

  Future<UserModel?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Dispara a leitura do perfil do usuário autenticado no banco de dados.
  void _loadProfile() {
    final user = _authService.currentUser;
    _profileFuture = user != null ? _authService.getUserProfile(user.uid) : null;
  }

  // Abre a edição do perfil e recarrega os dados caso as alterações tenham sido salvas.
  Future<void> _openProfileForm(UserModel userModel) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileFormScreen(user: userModel),
      ),
    );

    if (saved == true && mounted) {
      setState(() {
        _loadProfile();
      });
    }
  }

  // Constrói o aviso em destaque para usuários que ainda não cadastraram telefone.
  Widget _buildPhoneWarning(UserModel userModel) {
    return Material(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _openProfileForm(userModel),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.phone_outlined, color: Colors.amber.shade800, size: 28.0),
              const SizedBox(width: 12.0),
              const Expanded(
                child: Text(
                  'Adicione seu telefone para que a ONG possa entrar em contato.',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.amber.shade800),
            ],
          ),
        ),
      ),
    );
  }

  // Constrói o botão de acesso à edição dos dados do perfil.
  Widget _buildEditProfileButton(UserModel userModel) {
    return SecondaryButton(
      text: 'Editar Perfil',
      icon: const Icon(Icons.edit),
      onPressed: () => _openProfileForm(userModel),
    );
  }

  // Executa o encerramento de sessão do usuário logado.
  Future<void> _handleSignOut(BuildContext context) async {
    await _authService.signOut();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão encerrada com sucesso!')),
      );
      Navigator.pop(context);
    }
  }

  // Constrói o painel de atalhos administrativos.
  Widget _buildAdminPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.green, size: 28),
              SizedBox(width: 8.0),
              Text(
                'Painel Administrativo',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gerenciar ONGs'),
            subtitle: const Text('Aprovação e consulta de instituições cadastradas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NgoManagementScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Usuários do Sistema'),
            subtitle: const Text('Visualizar todas as contas registradas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Constrói o painel de atalhos e informações institucionais da ONG.
  Widget _buildNgoPanel(BuildContext context, UserModel userModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: userModel.isActive ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: userModel.isActive ? Colors.green.shade200 : Colors.amber.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                color: userModel.isActive ? Colors.green : Colors.amber.shade800,
                size: 28,
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Painel da Instituição',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          if (userModel.isActive && userModel.ngoId != null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Solicitações de Adoção'),
              subtitle: const Text('Gerenciar intenções recebidas de adotantes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdoptionManagementScreen(
                      ngoId: userModel.ngoId!,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Meus Animais Cadastrados'),
              subtitle: const Text('Visualizar, editar e remover resgates'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimalManagementScreen(
                      ngoId: userModel.ngoId!,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cadastrar Novo Animal'),
              subtitle: const Text('Publicar um novo animal para adoção'),
              trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnimalFormScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Editar Dados da ONG'),
              subtitle: const Text('Atualizar telefone, e-mail e endereço'),
              trailing: const Icon(Icons.edit, color: Colors.green),
              onTap: () async {
                final ngo = await NgoService().getNgoById(userModel.ngoId!);
                if (context.mounted && ngo != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NgoFormScreen(ngoToEdit: ngo),
                    ),
                  );
                }
              },
            ),
          ] else if (userModel.isUnderReview) ...[
            const Text(
              'Cadastro em Análise',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Sua instituição foi enviada para análise da administração. Em breve você receberá a liberação para publicar animais.',
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.grey.shade700,
              ),
            ),
          ] else ...[
            const Text(
              'Cadastro Não Aprovado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Sua solicitação de cadastro não foi aprovada. Entre em contato com o suporte para mais informações.',
              style: TextStyle(
                fontSize: 13.0,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Meu Perfil',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_profileFuture != null)
              FutureBuilder<UserModel?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final userModel = snapshot.data;

                  if (userModel == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Exibe o cartão padronizado com os dados do usuário.
                      UserCard(user: userModel),
                      const SizedBox(height: 16.0),

                      // Exibe o aviso em destaque caso o usuário ainda não tenha telefone cadastrado.
                      if (!userModel.hasPhone) ...[
                        _buildPhoneWarning(userModel),
                        const SizedBox(height: 16.0),
                      ],

                      _buildEditProfileButton(userModel),
                      const SizedBox(height: 24.0),

                      // Exibe o painel administrativo caso o usuário seja Admin.
                      if (userModel.isAdmin) _buildAdminPanel(context),

                      // Exibe o painel institucional caso o usuário seja representante de ONG.
                      if (userModel.isNgoRep) _buildNgoPanel(context, userModel),
                    ],
                  );
                },
              ),

            const SizedBox(height: 16.0),

            // Botão de desconexão.
            PrimaryButton(
              text: 'Sair da Conta',
              onPressed: () => _handleSignOut(context),
            ),
          ],
        ),
      ),
    );
  }
}