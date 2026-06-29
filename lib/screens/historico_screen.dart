import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import '../widgets/app_navbar.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});
  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List _devolucoes = [];
  List _emprestimosAtivos = [];
  List _turmas = [];
  bool _loading = true;

  String _buscaDevolucao = '';
  String _buscaEmprestimo = '';
  String _buscaDevolucaoTurma = '';
  String _buscaEmprestimoTurma = '';

  String _periodo = 'mes';
  DateTime? _dataInicio;
  DateTime? _dataFim;

  Set<String> _turmasExpandidasDevolucao = {};
  Set<String> _turmasExpandidasEmprestimo = {};

  final List<_PeriodoOpcao> _opcoesPeriodo = const [
    _PeriodoOpcao('hoje', 'Hoje'),
    _PeriodoOpcao('semana', 'Esta semana'),
    _PeriodoOpcao('mes', 'Este mês'),
    _PeriodoOpcao('tudo', 'Tudo'),
    _PeriodoOpcao('personalizado', 'Personalizado'),
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      api.getHistorico(),
      api.getEmprestimos(),
      api.getTurmas(),
    ]);
    setState(() {
      _devolucoes = results[0] as List;
      _emprestimosAtivos = results[1] as List;
      _turmas = results[2] as List;
      _loading = false;
    });
  }

  Future<void> _apagarRegistro(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (conf == true) {
      await api.deletarHistorico(id);
      setState(() => _devolucoes.removeWhere((h) => h['id'] == id));
    }
  }

  Future<void> _limpar() async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Limpar todo o histórico?'),
        content: const Text('Esta ação não pode ser desfeita!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (conf == true) {
      await api.limparHistorico();
      await _carregar();
    }
  }

  int _duracao(String? ini, String? fim) {
    if (ini == null || fim == null) return 0;
    return DateTime.parse(fim).difference(DateTime.parse(ini)).inDays;
  }

  bool _atrasado(Map h) {
    if (h['data_devolucao'] == null || h['data_prevista_devolucao'] == null) {
      return false;
    }
    return DateTime.parse(h['data_devolucao'])
        .isAfter(DateTime.parse(h['data_prevista_devolucao']));
  }

  List get _devolucoesPorPeriodo {
    final hoje = DateTime.now();
    return _devolucoes.where((h) {
      if (h['data_devolucao'] == null) return false;
      final data = DateTime.parse(h['data_devolucao']);
      if (_periodo == 'hoje') {
        return data.year == hoje.year &&
            data.month == hoje.month &&
            data.day == hoje.day;
      }
      if (_periodo == 'semana') {
        final inicio = hoje.subtract(Duration(days: hoje.weekday - 1));
        return data.isAfter(inicio.subtract(const Duration(days: 1)));
      }
      if (_periodo == 'mes') {
        return data.year == hoje.year && data.month == hoje.month;
      }
      if (_periodo == 'personalizado') {
        if (_dataInicio != null && data.isBefore(_dataInicio!)) return false;
        if (_dataFim != null &&
            data.isAfter(_dataFim!.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List get _devolucoesFiltradas => _devolucoesPorPeriodo.where((h) {
        final nomeAluno = (h['aluno']?['nome'] ?? '').toLowerCase();
        final turma = (h['aluno']?['turma'] ?? '').toLowerCase();
        final nomeLivro = (h['livro']?['nome'] ?? '').toLowerCase();
        final b = _buscaDevolucao.toLowerCase();
        return nomeAluno.contains(b) ||
            turma.contains(b) ||
            nomeLivro.contains(b);
      }).toList();

  List get _emprestimosFiltrados => _emprestimosAtivos.where((e) {
        final nomeAluno = (e['aluno']?['nome'] ?? '').toLowerCase();
        final turma = (e['aluno']?['turma'] ?? '').toLowerCase();
        final nomeLivro = (e['livro']?['nome'] ?? '').toLowerCase();
        final b = _buscaEmprestimo.toLowerCase();
        return nomeAluno.contains(b) ||
            turma.contains(b) ||
            nomeLivro.contains(b);
      }).toList();

  Map<String, List> get _devolucoesPorTurma {
    final g = <String, List>{};
    for (final t in _turmas) {
      final nome = t['nome'] as String;
      final items = _devolucoesFiltradas
          .where((h) => h['aluno']?['turma'] == nome)
          .toList();
      if (items.isNotEmpty) g[nome] = items;
    }
    final sem = _devolucoesFiltradas
        .where(
            (h) => h['aluno']?['turma'] == null || h['aluno']?['turma'] == '')
        .toList();
    if (sem.isNotEmpty) g['Sem turma'] = sem;
    return g;
  }

  Map<String, List> get _emprestimosPorTurma {
    final g = <String, List>{};
    for (final t in _turmas) {
      final nome = t['nome'] as String;
      final items = _emprestimosFiltrados
          .where((e) => e['aluno']?['turma'] == nome)
          .toList();
      if (items.isNotEmpty) g[nome] = items;
    }
    final sem = _emprestimosFiltrados
        .where(
            (e) => e['aluno']?['turma'] == null || e['aluno']?['turma'] == '')
        .toList();
    if (sem.isNotEmpty) g['Sem turma'] = sem;
    return g;
  }

  Map get _stats {
    final base = _devolucoesPorPeriodo;
    if (base.isEmpty) return {};
    final atrasados = base.where((h) => _atrasado(h)).length;
    final contLivros = <String, int>{};
    final contMembros = <String, int>{};
    for (final h in base) {
      final l = h['livro']?['nome'] ?? 'Desconhecido';
      final m = h['aluno']?['nome'] ?? 'Desconhecido';
      contLivros[l] = (contLivros[l] ?? 0) + 1;
      contMembros[m] = (contMembros[m] ?? 0) + 1;
    }
    final livroTop =
        contLivros.entries.reduce((a, b) => a.value > b.value ? a : b);
    final membroTop =
        contMembros.entries.reduce((a, b) => a.value > b.value ? a : b);
    return {
      'total': base.length,
      'atrasados': atrasados,
      'percentual': ((atrasados / base.length) * 100).round(),
      'livroTop': livroTop.key,
      'livroTopQtd': livroTop.value,
      'membroTop': membroTop.key,
      'membroTopQtd': membroTop.value,
    };
  }

  String _formatData(String? d) {
    if (d == null) return '-';
    final dt = DateTime.tryParse(d)?.toLocal();
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    return Scaffold(
      appBar: const AppNavbar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: Column(
                children: [
                  // Cabeçalho
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Histórico',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildPeriodoFiltro(),
                  if (_periodo == 'personalizado') _buildPersonalizado(),
                  if (s.isNotEmpty) _buildStats(s),
                  // Duas colunas
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna esquerda: Devoluções
                        Expanded(
                          flex: 1,
                          child: _buildDevolucoesColuna(),
                        ),
                        const VerticalDivider(width: 1),
                        // Coluna direita: Empréstimos ativos
                        Expanded(
                          flex: 1,
                          child: _buildEmprestimosColuna(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodoFiltro() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Período: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          ..._opcoesPeriodo.map((op) {
            final selected = _periodo == op.value;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _periodo = op.value),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF2563EB) : Colors.white,
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    op.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPersonalizado() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _dataInicio = d);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _dataInicio != null
                      ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'
                      : 'Data início',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('até'),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _dataFim = d);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _dataFim != null
                      ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}'
                      : 'Data fim',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _limpar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpar histórico'),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(Map s) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _statCard('${s['total']}', 'Devoluções', const Color(0xFF2563EB)),
          _statCard(
            '${s['percentual']}%',
            'Com atraso',
            (s['percentual'] as int) > 20
                ? const Color(0xFFDC2626)
                : const Color(0xFF16A34A),
          ),
          _statCardText(
            '${s['livroTop']}',
            'Livro mais emprestado (${s['livroTopQtd']}x)',
            const Color(0xFF7C3AED),
          ),
          _statCardText(
            '${s['membroTop']}',
            'Membro mais ativo (${s['membroTopQtd']}x)',
            const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildDevolucoesColuna() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            'Devoluções',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar devoluções...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _buscaDevolucao = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildDevolucaoGeral(),
              const SizedBox(height: 12),
              const Text(
                'Por turma',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._devolucoesPorTurma.entries.map(_buildDevolucaoTurmaCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevolucaoGeral() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Todas',
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${_devolucoesFiltradas.length} registros',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {},
          ),
          SizedBox(
            height: 200,
            child: _devolucoesFiltradas.isEmpty
                ? const Center(
                    child: Text('Nenhuma devolução.',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children:
                        _devolucoesFiltradas.map((h) => _histCard(h)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevolucaoTurmaCard(MapEntry<String, List> entry) {
    final nome = entry.key;
    final items = entry.value;
    final expandida = _turmasExpandidasDevolucao.contains(nome);
    final temAtrasado = items.any((h) => _atrasado(h));
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title:
                Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle:
                Text('${items.length} registro${items.length != 1 ? 's' : ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (temAtrasado)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'houve atraso',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                Icon(expandida ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: () => setState(() {
              expandida
                  ? _turmasExpandidasDevolucao.remove(nome)
                  : _turmasExpandidasDevolucao.add(nome);
            }),
          ),
          if (expandida)
            SizedBox(
              height: 200,
              child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: items.map((h) => _histCard(h)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmprestimosColuna() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            'Empréstimos ativos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar empréstimos...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _buscaEmprestimo = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildEmprestimoGeral(),
              const SizedBox(height: 12),
              const Text(
                'Por turma',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._emprestimosPorTurma.entries.map(_buildEmprestimoTurmaCard),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmprestimoGeral() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Todos',
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              '${_emprestimosFiltrados.length} empréstimos',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {},
          ),
          SizedBox(
            height: 200,
            child: _emprestimosFiltrados.isEmpty
                ? const Center(
                    child: Text('Nenhum empréstimo ativo.',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children:
                        _emprestimosFiltrados.map((e) => _empCard(e)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmprestimoTurmaCard(MapEntry<String, List> entry) {
    final nome = entry.key;
    final items = entry.value;
    final expandida = _turmasExpandidasEmprestimo.contains(nome);
    final temAtrasado = items.any((e) => e['atrasado'] == true);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            title:
                Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${items.length} empréstimo${items.length != 1 ? 's' : ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (temAtrasado)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'com atraso',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                Icon(expandida ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: () => setState(() {
              expandida
                  ? _turmasExpandidasEmprestimo.remove(nome)
                  : _turmasExpandidasEmprestimo.add(nome);
            }),
          ),
          if (expandida)
            SizedBox(
              height: 200,
              child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: items.map((e) => _empCard(e)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _histCard(Map h) {
    final atrasado = _atrasado(h);
    final dias = _duracao(h['data_emprestimo'], h['data_devolucao']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h['aluno']?['nome'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(h['livro']?['nome'] ?? '',
                    style: const TextStyle(fontSize: 13)),
                Text(
                  '${_formatData(h['data_emprestimo'])} → ${_formatData(h['data_devolucao'])} · $dias dias',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: atrasado
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    atrasado ? 'Atrasado' : 'No prazo',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Color(0xFFDC2626)),
            onPressed: () => _apagarRegistro(h['id']),
          ),
        ],
      ),
    );
  }

  Widget _empCard(Map e) {
    final atrasado = e['atrasado'] == true;
    final dataStr = e['data_prevista_devolucao'] as String?;
    final data = dataStr != null ? DateTime.tryParse(dataStr)?.toLocal() : null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: atrasado ? const Color(0xFFFEE2E2) : Colors.white,
        border: Border.all(
          color: atrasado ? const Color(0xFFDC2626) : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e['aluno']?['nome'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(e['livro']?['nome'] ?? '',
                    style: const TextStyle(fontSize: 13)),
                if (data != null)
                  Text(
                    'Devolver até: ${data.day}/${data.month}/${data.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: atrasado ? const Color(0xFFDC2626) : Colors.grey,
                    ),
                  ),
                if (atrasado)
                  const Text(
                    'ATRASADO',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.grey),
            onPressed: () {}, // não permite apagar empréstimo ativo aqui
          ),
        ],
      ),
    );
  }

  Widget _statCard(String valor, String label, Color cor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: cor, width: 3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: cor),
            ),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _statCardText(String valor, String label, Color cor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: cor, width: 3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: cor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _PeriodoOpcao {
  final String value;
  final String label;
  const _PeriodoOpcao(this.value, this.label);
}
