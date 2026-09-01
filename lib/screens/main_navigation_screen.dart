import 'package:flutter/material.dart';
import '../main.dart'; // Importa para acessar a HomePage atual
import 'login_screen.dart';

// Gerencia a navegacao principal do aplicativo utilizando uma barra inferior enxuta.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Define as telas disponiveis para a visao do visitante (sem a aba de cadastro).
  final List<Widget> _screens = [
    HomePage(),
    const LoginScreen(),
  ];

  // Atualiza o indice ativo e aciona a reconstrucao da interface.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        indicatorColor: Colors.green.shade100,
        // Força uma altura mais compacta para a barra de navegacao.
        height: 60.0,
        // Desativa a renderizacao dos textos, deixando o visual focado apenas nos icones.
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets, color: Colors.green),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.green),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}