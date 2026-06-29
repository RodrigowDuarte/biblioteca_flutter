import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import '../widgets/app_navbar.dart';

class EmprestimosScreen extends StatefulWidget {
  const EmprestimosScreen({super.key});

  @override
  State<EmprestimosScreen> createState() => _EmprestimosScreenState();
}

class _EmprestimosScreenState extends State<EmprestimosScreen> {
  List<Map<String, dynamic>> _emprestimos = [];
  List<Map<String, dynamic>> _alunos = [];
  List<Map<String, dynamic>> _livros = [];
  List<Map<String, dynamic>> _turmas = [];
  bool _loading = true;
  String _busca = '';
  String _modoBusca = 'titulo';
  final Set<String> _turmasExpandidas = {};

  Map<String, dynamic>? _alunoSelecionado;
  Map<String, dynamic>? _livroSelecionado;
  String _buscaAluno = '';
  String _buscaLivro = '';
  int _dias = 7;
  String _mensagem = '';
  String _erro = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      api.getEmprestimos(),
      api.getAlunos(),
      api.getLivros(),
      api.getTurmas(),
    ]);
    setState(() {
      _emprestimos = List<Map<String, dynamic>>.from(results[0]);
      _alunos = List<Map<String, dynamic>>.from(results[1]);
      _livros = List<Map<String, dynamic>>.from(results[2]);
      _turmas = List<Map<String, dynamic>>.from(results[3]);
      _loading = false;
    });
  }

  Future<void> _emprestar() async {
    if (_alunoSelecionado == null || _livroSelecionado == null) {
      setState(() => _erro = 'Selecione um membro e um livro!');
      return;
    }
    final res = await api.emprestar({
      'aluno_id': _alunoSelecionado!['id'],
      'livro_id': _livroSelecionado!['id'],
      'dias': _dias,
    });
    if (res['id'] != null) {
      setState(() {
        _mensagem = 'Livro emprestado com sucesso!';
        _alunoSelecionado = null;
        _livroSelecionado = null;
        _buscaAluno = '';
        _buscaLivro = '';
        _erro = '';
      });
      await _carregar();
    } else {
      setState(() => _erro = res['message'] ?? 'Erro ao emprestar');
    }
  }

  Future<void> _devolver(int id) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar devolução?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );
    if (conf == true) {
      await api.devolver({'emprestimo_id': id});
      setState(() => _mensagem = 'Livro devolvido com sucesso!');
      await _carregar();
    }
  }

  List<Map<String, dynamic>> get _alunosFiltrados {
    if (_buscaAluno.isEmpty || _alunoSelecionado != null) return [];
    return _alunos.where((a) {
      final nome = (a['nome'] ?? '').toString().toLowerCase();
      return nome.contains(_buscaAluno.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> get _livrosFiltrados {
    if (_buscaLivro.isEmpty || _livroSelecionado != null) return [];
    return _livros.where((l) {
      final nome = (l['nome'] ?? '').toString().toLowerCase();
      final disp = (l['quantidade_disponivel'] ?? 0) as int;
      return nome.contains(_buscaLivro.toLowerCase()) && disp > 0;
    }).toList();
  }

  List<Map<String, dynamic>> get _empsFiltrados {
    final b = _busca.toLowerCase();
    return _emprestimos.where((e) {
      final valor = _modoBusca == 'titulo'
          ? (e['livro']?['nome'] ?? '').toString()
          : (e['aluno']?['nome'] ?? '').toString();
      return valor.toLowerCase().contains(b);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get _porTurma {
    final Map<String, List<Map<String, dynamic>>> g = {};
    for (final t in _turmas) {
      final nome = t['nome'] as String;
      final ativos = _emprestimos.where((e) {
        return e['aluno']?['turma'] == nome;
      }).toList();
      if (ativos.isNotEmpty) g[nome] = ativos;
    }
    final sem = _emprestimos.where((e) {
      final turma = e['aluno']?['turma'];
      return turma == null || turma == '';
    }).toList();
    if (sem.isNotEmpty) g['Sem turma'] = sem;
    return g;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_mensagem.isNotEmpty)
                      _aviso(_mensagem, const Color(0xFF16A34A),
                          const Color(0xFFDCFCE7)),
                    if (_erro.isNotEmpty)
                      _aviso(_erro, const Color(0xFFDC2626),
                          const Color(0xFFFEE2E2)),
                    _buildEmprestarCard(),
                    const SizedBox(height: 16),
                    _buildAtivosCard(),
                    const SizedBox(height: 16),
                    _buildPorTurmaCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmprestarCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Emprestar Livro',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Buscar Membro',
                  border: OutlineInputBorder(),
                  isDense: true),
              onChanged: (v) => setState(() {
                _buscaAluno = v;
                _alunoSelecionado = null;
              }),
            ),
            if (_alunosFiltrados.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4)),
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView(
                  shrinkWrap: true,
                  children: _alunosFiltrados.map((a) {
                    return ListTile(
                      dense: true,
                      title: Text(a['nome'] ?? ''),
                      subtitle:
                          Text('${a['turma'] ?? '-'} · ${a['tipo'] ?? ''}'),
                      onTap: () => setState(() {
                        _alunoSelecionado = a;
                        _buscaAluno = a['nome'] ?? '';
                      }),
                    );
                  }).toList(),
                ),
              ),
            if (_alunoSelecionado != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Selecionado: ${_alunoSelecionado!['nome']}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _alunoSelecionado = null;
                        _buscaAluno = '';
                      }),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Buscar Livro',
                  border: OutlineInputBorder(),
                  isDense: true),
              onChanged: (v) => setState(() {
                _buscaLivro = v;
                _livroSelecionado = null;
              }),
            ),
            if (_livrosFiltrados.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4)),
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView(
                  shrinkWrap: true,
                  children: _livrosFiltrados.map((l) {
                    return ListTile(
                      dense: true,
                      title: Text(l['nome'] ?? ''),
                      subtitle:
                          Text('Disponível: ${l['quantidade_disponivel']}'),
                      onTap: () => setState(() {
                        _livroSelecionado = l;
                        _buscaLivro = l['nome'] ?? '';
                      }),
                    );
                  }).toList(),
                ),
              ),
            if (_livroSelecionado != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Selecionado: ${_livroSelecionado!['nome']}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _livroSelecionado = null;
                        _buscaLivro = '';
                      }),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Prazo (dias): '),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() {
                    if (_dias > 1) _dias--;
                  }),
                ),
                Text('$_dias',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _dias++),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _emprestar, child: const Text('Emprestar')),
          ],
        ),
      ),
    );
  }

  Widget _buildAtivosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Empréstimos Ativos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _filtroBtn('Por Título', 'titulo'),
                const SizedBox(width: 8),
                _filtroBtn('Por Aluno', 'aluno'),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                  hintText: _modoBusca == 'titulo'
                      ? 'Pesquisar por título...'
                      : 'Pesquisar por aluno...',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: const Icon(Icons.search)),
              onChanged: (v) => setState(() => _busca = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: _empsFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum empréstimo ativo.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: _empsFiltrados.map((e) => _empCard(e)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPorTurmaCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Empréstimos por Turma',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 300,
              child: _porTurma.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum empréstimo ativo.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: _porTurma.entries.map((entry) {
                        final nome = entry.key;
                        final emps = entry.value;
                        final expandida = _turmasExpandidas.contains(nome);
                        final temAtrasado =
                            emps.any((e) => e['atrasado'] == true);
                        return ExpansionTile(
                          title: Text(nome,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${emps.length} empréstimo${emps.length != 1 ? 's' : ''}'),
                          trailing: temAtrasado
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: const Text('atrasado',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                )
                              : null,
                          children: emps.map((e) => _empCard(e)).toList(),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empCard(Map<String, dynamic> e) {
    final atrasado = e['atrasado'] == true;
    final dataStr = e['data_prevista_devolucao'] as String?;
    final data = dataStr != null ? DateTime.tryParse(dataStr)?.toLocal() : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: atrasado ? const Color(0xFFFEE2E2) : Colors.white,
        border: Border.all(
            color: atrasado ? const Color(0xFFDC2626) : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['livro']?['nome'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    '${e['aluno']?['nome'] ?? ''} ${e['aluno']?['turma'] != null ? "— ${e['aluno']['turma']}" : ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                if (data != null)
                  Text('Devolver até: ${data.day}/${data.month}/${data.year}',
                      style: TextStyle(
                          fontSize: 12,
                          color: atrasado
                              ? const Color(0xFFDC2626)
                              : Colors.grey)),
                if (atrasado)
                  const Text('ATRASADO',
                      style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _devolver(e['id'] as int),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
            child: const Text('Devolver', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _aviso(String msg, Color cor, Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(msg, style: TextStyle(color: cor)),
    );
  }

  Widget _filtroBtn(String label, String modo) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _modoBusca = modo;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _modoBusca == modo ? const Color(0xFF2563EB) : Colors.white,
          border: Border.all(
            color: _modoBusca == modo
                ? const Color(0xFF2563EB)
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: _modoBusca == modo ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
