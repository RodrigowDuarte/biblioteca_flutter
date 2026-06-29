import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/membros_screen.dart';
import '../screens/livros_screen.dart';
import '../screens/emprestimos_screen.dart';
import '../screens/inadimplentes_screen.dart';
import '../screens/turmas_screen.dart';
import '../screens/localizacao_screen.dart';
import '../screens/historico_screen.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavbar({super.key});

  Future<void> _logout(BuildContext context) async {
    await api.removeToken();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1F2937),
      title: GestureDetector(
        onTap: () => _goToHome(context),
        child: const Text(
          'Biblioteca',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      actions: [
        _navItem(context, 'Membros', const MembrosScreen()),
        _navItem(context, 'Livros', const LivrosScreen()),
        _navItem(context, 'Empréstimos', const EmprestimosScreen()),
        _navItem(context, 'Inadimplentes', const InadimplentesScreen()),
        _navItem(context, 'Turmas', const TurmasScreen()),
        _navItem(context, 'Localização', const LocalizacaoScreen()),
        _navItem(context, 'Histórico', const HistoricoScreen()),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () => _logout(context),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
          ),
          child: const Text('Sair'),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _navItem(BuildContext context, String label, Widget page) {
    return TextButton(
      onPressed: () => _go(context, page),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
