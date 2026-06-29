import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import '../widgets/app_navbar.dart';

class MembrosScreen extends StatefulWidget {
  const MembrosScreen({super.key});

  @override
  State<MembrosScreen> createState() => _MembrosScreenState();
}

class _MembrosScreenState extends State<MembrosScreen> {
  List<dynamic> _alunos = [];
  List<dynamic> _turmas = [];
  bool _loading = true;
  String _busca = '';
  final TextEditingController _buscaCtrl = TextEditingController();
  final Set<String> _turmasExpandidas = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      api.getAlunos(),
      api.getTurmas(),
    ]);
    setState(() {
      _alunos = results[0] as List;
      _turmas = results[1] as List;
      _loading = false;
    });
  }

  List<dynamic> get _filtrados {
    final b = _busca.toLowerCase();
    return _alunos.where((a) {
      final nome = (a['nome'] ?? '').toString().toLowerCase();
      final cpf = (a['cpf'] ?? '').toString();
      final turma = (a['turma'] ?? '').toString().toLowerCase();
      return nome.contains(b) || cpf.contains(b) || turma.contains(b);
    }).toList();
  }

  Map<String, List<dynamic>> get _grupos {
    final Map<String, List<dynamic>> g = {};
    for (final t in _turmas) {
      final nome = t['nome'];
      final membros = _filtrados.where((a) => a['turma'] == nome).toList();
      if (membros.isNotEmpty) {
        g[nome] = membros;
      }
    }
    final semTurma =
        _filtrados.where((a) => (a['turma'] ?? '').isEmpty).toList();
    if (semTurma.isNotEmpty) {
      g['Sem turma'] = semTurma;
    }
    return g;
  }

  Map<String, int> get _stats => {
        'total': _alunos.length,
        'inadimplentes': _alunos.where((a) => a['inadimplente'] == true).length,
        'comLivro': _alunos
            .where(
                (a) => a['tem_emprestimo'] == true && a['inadimplente'] != true)
            .length,
        'emDia': _alunos.where((a) => a['tem_emprestimo'] != true).length,
      };

  void _abrirForm([Map? aluno]) {
    final nomeCtrl = TextEditingController(text: aluno?['nome'] ?? '');
    final cpfCtrl = TextEditingController(text: aluno?['cpf'] ?? '');
    final telCtrl = TextEditingController(text: aluno?['telefone'] ?? '');
    final emailCtrl = TextEditingController(text: aluno?['email'] ?? '');
    final endCtrl = TextEditingController(text: aluno?['endereco'] ?? '');
    String tipo = aluno?['tipo'] ?? 'aluno';
    String? turmaSelecionada = aluno?['turma'];

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
                width: 500,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno != null ? 'Editar Membro' : 'Novo Membro',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nome *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cpfCtrl,
                      decoration: const InputDecoration(
                          labelText: 'CPF', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: telCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Telefone', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Email', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Endereço', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tipo,
                      decoration: const InputDecoration(
                          labelText: 'Tipo', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'aluno', child: Text('Aluno')),
                        DropdownMenuItem(
                            value: 'professor', child: Text('Professor')),
                      ],
                      onChanged: (v) => setModal(() => tipo = v!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: turmaSelecionada,
                      decoration: const InputDecoration(
                          labelText: 'Turma', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(
                            value: '', child: Text('Sem turma')),
                        ..._turmas.map((t) {
                          final nome = t['nome'] as String;
                          return DropdownMenuItem(
                              value: nome, child: Text(nome));
                        }),
                      ],
                      onChanged: (v) => setModal(() => turmaSelecionada = v),
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
                              'cpf': cpfCtrl.text.trim(),
                              'telefone': telCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'endereco': endCtrl.text.trim(),
                              'tipo': tipo,
                              'turma': turmaSelecionada ?? '',
                            };
                            if (aluno != null) {
                              await api.updateAluno(aluno['id'], data);
                            } else {
                              await api.createAluno(data);
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

  Future<void> _remover(Map aluno) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover membro?'),
        content: Text('Deseja remover ${aluno['nome'] ?? 'este membro'}?'),
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
    if (ok == true) {
      await api.deleteAluno(aluno['id']);
      await _carregar();
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
                // Cabeçalho com título e botão "Novo"
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Membros',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _abrirForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Busca
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _buscaCtrl,
                    onChanged: (v) => setState(() => _busca = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar membros...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _stat(_stats['total']!, 'Total'),
                      _stat(_stats['emDia']!, 'Em dia'),
                      _stat(_stats['comLivro']!, 'Com livro'),
                      _stat(_stats['inadimplentes']!, 'Inadimplentes'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Duas colunas: Membros por turma | Todos os membros
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Coluna esquerda: Membros por turma
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Text(
                                'Membros por turma',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                children: _grupos.entries.map((e) {
                                  final nome = e.key;
                                  final membros = e.value;
                                  final open = _turmasExpandidas.contains(nome);
                                  final inad = membros
                                      .where((m) => m['inadimplente'] == true)
                                      .length;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Text(nome,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          subtitle: Text(
                                              '${membros.length} membro${membros.length != 1 ? 's' : ''}'),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (inad > 0)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    '$inad inad.',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11),
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              Icon(open
                                                  ? Icons.expand_less
                                                  : Icons.expand_more),
                                            ],
                                          ),
                                          onTap: () {
                                            setState(() {
                                              open
                                                  ? _turmasExpandidas
                                                      .remove(nome)
                                                  : _turmasExpandidas.add(nome);
                                            });
                                          },
                                        ),
                                        if (open)
                                          ...membros
                                              .map((m) => _buildMembroItem(m)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Coluna direita: Todos os membros
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: Text(
                                'Todos os membros',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _filtrados.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Nenhum membro encontrado',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        itemCount: _filtrados.length,
                                        itemBuilder: (_, i) {
                                          final m = _filtrados[i];
                                          return _buildMembroItem(m);
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMembroItem(Map m) {
    final inadimplente = m['inadimplente'] == true;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: inadimplente ? Colors.red : Colors.green,
        radius: 14,
        child: Text(
          (m['nome'] ?? '')[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      title: Text(
        m['nome'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text('${m['cpf'] ?? '-'} • ${m['telefone'] ?? '-'}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => _abrirForm(m),
            color: Colors.orange,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: () => _remover(m),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _stat(int v, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text('$v',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
