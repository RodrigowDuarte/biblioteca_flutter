import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import '../widgets/app_navbar.dart';

class TurmasScreen extends StatefulWidget {
  const TurmasScreen({super.key});
  @override
  State<TurmasScreen> createState() => _TurmasScreenState();
}

class _TurmasScreenState extends State<TurmasScreen> {
  List _turmas = [];
  List _membros = [];
  Map? _turmaSelecionada;
  bool _loading = true;
  String _busca = '';
  String _tela = 'turmas';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    _turmas = await api.getTurmas() as List;
    setState(() => _loading = false);
  }

  Future<void> _abrirTurma(Map turma) async {
    setState(() {
      _loading = true;
      _turmaSelecionada = turma;
      _tela = 'membros';
      _busca = '';
    });
    final res = await api.getMembrosDaTurma(turma['id']);
    setState(() {
      _membros = (res['membros'] ?? []) as List;
      _loading = false;
    });
  }

  void _abrirFormTurma([Map? editando]) {
    final nomeCtrl = TextEditingController(text: editando?['nome'] ?? '');
    final descCtrl = TextEditingController(text: editando?['descricao'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editando != null ? 'Editar Turma' : 'Nova Turma',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (nomeCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text('Nome é obrigatório')),
                              );
                              return;
                            }
                            final data = {
                              'nome': nomeCtrl.text.trim(),
                              'descricao': descCtrl.text.trim(),
                            };
                            if (editando != null) {
                              await api.updateTurma(editando['id'], data);
                            } else {
                              await api.createTurma(data);
                            }
                            if (mounted) Navigator.pop(ctx);
                            await _carregar();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removerTurma(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover turma?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (conf == true) {
      await api.deleteTurma(id);
      await _carregar();
    }
  }

  List get _turmasFiltradas => _turmas
      .where((t) =>
          (t['nome'] ?? '').toLowerCase().contains(_busca.toLowerCase()) ||
          (t['descricao'] ?? '').toLowerCase().contains(_busca.toLowerCase()))
      .toList();

  List get _membrosOrdenados => [
        ..._membros.where((m) => m['inadimplente'] == true),
        ..._membros.where(
            (m) => m['tem_emprestimo'] == true && m['inadimplente'] != true),
        ..._membros.where(
            (m) => m['tem_emprestimo'] != true && m['inadimplente'] != true),
      ]
          .where((m) =>
              (m['nome'] ?? '').toLowerCase().contains(_busca.toLowerCase()))
          .toList();

  Map get _stats => {
        'total': _membros.length,
        'inadimplentes':
            _membros.where((m) => m['inadimplente'] == true).length,
        'comLivro': _membros
            .where(
                (m) => m['tem_emprestimo'] == true && m['inadimplente'] != true)
            .length,
        'emDia': _membros
            .where(
                (m) => m['tem_emprestimo'] != true && m['inadimplente'] != true)
            .length,
      };

  Widget _buildHeader() {
    if (_tela == 'turmas') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            const Text(
              'Turmas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _abrirFormTurma(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nova Turma'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _tela = 'turmas';
                _turmaSelecionada = null;
                _membros = [];
              }),
            ),
            Text(
              'Turmas',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Text(' › ', style: TextStyle(color: Colors.grey)),
            Text(
              _turmaSelecionada?['nome'] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavbar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _tela == 'turmas' ? _buildTurmas() : _buildMembros(),
                ),
              ],
            ),
    );
  }

  Widget _buildTurmas() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Pesquisar turma...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          Expanded(
            child: _turmasFiltradas.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma turma cadastrada.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.count(
                    padding: const EdgeInsets.all(12),
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: _turmasFiltradas.map((t) {
                      final totalMembros = t['total_membros'] ?? 0;
                      final totalInadimplentes = t['total_inadimplentes'] ?? 0;
                      return GestureDetector(
                        onTap: () => _abrirTurma(t),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: totalInadimplentes > 0
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      t['nome'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$totalMembros',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const Text(
                                          'membros',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (t['descricao'] != null &&
                                    t['descricao'] != '')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      t['descricao'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                if (totalInadimplentes > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$totalInadimplentes inad.',
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _abrirFormTurma(t),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD97706),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Editar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _removerTurma(t['id']),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Remover',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      );

  Widget _buildMembros() => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _statCard(
                    '${_stats['total']}', 'Total', const Color(0xFF2563EB)),
                _statCard(
                    '${_stats['emDia']}', 'Em dia', const Color(0xFF16A34A)),
                _statCard('${_stats['comLivro']}', 'Com livro',
                    const Color(0xFFD97706)),
                _statCard('${_stats['inadimplentes']}', 'Inadim.',
                    const Color(0xFFDC2626)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Pesquisar membro...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _membrosOrdenados.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum membro nesta turma.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _membrosOrdenados.length,
                    itemBuilder: (_, i) {
                      final m = _membrosOrdenados[i];
                      final inadimplente = m['inadimplente'] == true;
                      final comLivro =
                          m['tem_emprestimo'] == true && !inadimplente;
                      Color cor = inadimplente
                          ? const Color(0xFFDC2626)
                          : comLivro
                              ? const Color(0xFFD97706)
                              : const Color(0xFF16A34A);
                      String situacao = inadimplente
                          ? 'Inadimplente'
                          : comLivro
                              ? 'Com livro'
                              : 'Em dia';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: inadimplente
                            ? const Color(0xFFFFF5F5)
                            : Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cor,
                            radius: 14,
                            child: Text(
                              (m['nome'] ?? '')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            m['nome'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${m['tipo'] ?? ''} · ${m['cpf'] ?? '-'}'),
                              if (m['emprestimos'] != null &&
                                  (m['emprestimos'] as List).isNotEmpty)
                                ...(m['emprestimos'] as List).map((e) => Text(
                                      e['livro']?['nome'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    )),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              situacao,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );

  Widget _statCard(String valor, String label, Color cor) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(color: cor, width: 3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
}
