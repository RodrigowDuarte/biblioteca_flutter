import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import 'login_screen.dart';
import '../widgets/app_navbar.dart';
import 'membros_screen.dart';
import 'livros_screen.dart';
import 'emprestimos_screen.dart';
import 'turmas_screen.dart';
import 'historico_screen.dart';
import 'localizacao_screen.dart';
import 'inadimplentes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stats = {};
  List<dynamic> _inadimplentes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final results = await Future.wait([
        api.getAlunos(),
        api.getLivros(),
        api.getInadimplentes(),
        api.getEmprestimos(),
        api.getTurmas(),
      ]);

      final alunos = results[0] as List;
      final livros = results[1] as List;
      final inadimplentes = results[2] as List;
      final emprestimos = results[3] as List;
      final turmas = results[4] as List;

      setState(() {
        _inadimplentes = inadimplentes;
        _stats = {
          'membros': alunos.length,
          'livros': livros.length,
          'disponiveis':
              livros.where((l) => l['status'] == 'disponivel').length,
          'inadimplentes': inadimplentes.length,
          'emprestimos': emprestimos.length,
          'turmas': turmas.length,
        };
        _loading = false;
      });
    } catch (e) {
      debugPrint('HomeScreen error: $e');
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _inadFiltrados => _inadimplentes;

  void _navegarParaInadimplentes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InadimplentesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavbar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sistema de Biblioteca',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Selecione uma área para começar.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                            children: [
                              _card('Membros', Icons.people, _stats['membros'],
                                  Colors.blue, const MembrosScreen()),
                              _card('Livros', Icons.menu_book, _stats['livros'],
                                  Colors.green, const LivrosScreen()),
                              _card(
                                  'Empréstimos',
                                  Icons.swap_horiz,
                                  _stats['emprestimos'],
                                  Colors.orange,
                                  const EmprestimosScreen()),
                              _card('Turmas', Icons.class_, _stats['turmas'],
                                  Colors.purple, const TurmasScreen()),
                              _card('Histórico', Icons.history, null,
                                  Colors.teal, const HistoricoScreen()),
                              _card('Localização', Icons.location_on, null,
                                  Colors.indigo, const LocalizacaoScreen()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _navegarParaInadimplentes,
                        child: Container(
                          height: MediaQuery.of(context).size.height - 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              top: BorderSide(
                                color: Colors.red.shade700,
                                width: 4,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Inadimplentes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade700,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_inadFiltrados.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: _inadFiltrados.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.green.shade300,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Nenhum inadimplente',
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        itemCount: _inadFiltrados.length,
                                        itemBuilder: (_, i) {
                                          final item = _inadFiltrados[i];
                                          final aluno = item['aluno'] ?? {};
                                          final livro = item['livro'] ?? {};
                                          return GestureDetector(
                                            onTap: _navegarParaInadimplentes,
                                            child: Card(
                                              margin: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                leading: CircleAvatar(
                                                  backgroundColor:
                                                      Colors.red.shade100,
                                                  radius: 16,
                                                  child: Text(
                                                    (aluno['nome'] ?? '?')[0]
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                title: Text(
                                                  aluno['nome'] ??
                                                      'Desconhecido',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  livro['nome'] ??
                                                      'Livro não informado',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                trailing: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade700,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    '${item['dias_atraso'] ?? ''}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card(
    String titulo,
    IconData icon,
    int? count,
    Color color,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (count != null)
              Text(
                '$count registros',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
