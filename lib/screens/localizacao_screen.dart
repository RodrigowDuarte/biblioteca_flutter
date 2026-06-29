import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import '../widgets/app_navbar.dart';

class LocalizacaoScreen extends StatefulWidget {
  const LocalizacaoScreen({super.key});
  @override
  State<LocalizacaoScreen> createState() => _LocalizacaoScreenState();
}

class _LocalizacaoScreenState extends State<LocalizacaoScreen> {
  List _setores = [];
  List _livrosTodos = [];
  Map? _setorSelecionado;
  Map? _estanteSelecionada;
  String _tela = 'lista';
  bool _loading = true;
  String _mensagem = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final results = await Future.wait([api.getSetores(), api.getLivros()]);
    setState(() {
      _setores = results[0] as List;
      _livrosTodos = results[1] as List;
      _loading = false;
    });
  }

  Future<void> _recarregar() async {
    final setorId = _setorSelecionado?['id'];
    final estanteId = _estanteSelecionada?['id'];
    await _carregar();
    if (setorId != null)
      _setorSelecionado =
          _setores.firstWhere((s) => s['id'] == setorId, orElse: () => null);
    if (_setorSelecionado != null && estanteId != null) {
      final estantes = (_setorSelecionado!['estantes'] ?? []) as List;
      _estanteSelecionada =
          estantes.firstWhere((e) => e['id'] == estanteId, orElse: () => null);
    }
    setState(() {});
  }

  List get _livrosDaEstante => _estanteSelecionada == null
      ? []
      : _livrosTodos
          .where((l) =>
              l['estante_id'] != null &&
              l['estante_id'].toString() ==
                  _estanteSelecionada!['id'].toString())
          .toList();

  List _livrosDaEstanteById(int id) => _livrosTodos
      .where((l) =>
          l['estante_id'] != null &&
          l['estante_id'].toString() == id.toString())
      .toList();

  void _mostrarFormSetor([Map? editando]) {
    final nomeCtrl = TextEditingController(text: editando?['nome'] ?? '');
    final descCtrl = TextEditingController(text: editando?['descricao'] ?? '');
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(editando != null ? 'Editar Setor' : 'Novo Setor',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nome *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () async {
                              final data = {
                                'nome': nomeCtrl.text,
                                'descricao': descCtrl.text
                              };
                              if (editando != null)
                                await api.updateSetor(editando['id'], data);
                              else
                                await api.createSetor(data);
                              if (mounted) Navigator.pop(ctx);
                              await _recarregar();
                            },
                            child: const Text('Salvar'))),
                    const SizedBox(width: 8),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                  ]),
                  const SizedBox(height: 16),
                ])));
  }

  void _mostrarFormEstante([Map? editando]) {
    final nomeCtrl = TextEditingController(text: editando?['nome'] ?? '');
    final descCtrl = TextEditingController(text: editando?['descricao'] ?? '');
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(editando != null ? 'Editar Estante' : 'Nova Estante',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: nomeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nome *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () async {
                              final data = {
                                'nome': nomeCtrl.text,
                                'descricao': descCtrl.text,
                                'setor_id': _setorSelecionado!['id']
                              };
                              if (editando != null)
                                await api.updateEstante(editando['id'], data);
                              else
                                await api.createEstante(data);
                              if (mounted) Navigator.pop(ctx);
                              await _recarregar();
                            },
                            child: const Text('Salvar'))),
                    const SizedBox(width: 8),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar')),
                  ]),
                  const SizedBox(height: 16),
                ])));
  }

  void _mostrarFormLivro([Map? editando]) {
    final nomeCtrl = TextEditingController(text: editando?['nome'] ?? '');
    final isbnCtrl = TextEditingController(text: editando?['isbn'] ?? '');
    final autorCtrl = TextEditingController(text: editando?['autor'] ?? '');
    final patriCtrl =
        TextEditingController(text: editando?['n_patrimonio'] ?? '');
    final qtdCtrl =
        TextEditingController(text: '${editando?['quantidade'] ?? 1}');
    String categoria = editando?['categoria'] ?? 'livro';

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setS) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 16),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      Text(
                          editando != null
                              ? 'Editar Livro'
                              : 'Novo Livro — ${_estanteSelecionada?['nome']}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: nomeCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Título *',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(
                          controller: autorCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Autor',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(
                          controller: isbnCtrl,
                          decoration: const InputDecoration(
                              labelText: 'ISBN', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(
                          controller: patriCtrl,
                          decoration: const InputDecoration(
                              labelText: 'N. Patrimônio',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(
                          controller: qtdCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Quantidade',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: categoria,
                        decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder()),
                        items: ['livro', 'revista', 'colecao', 'jornal', 'gibi']
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setS(() => categoria = v!),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: ElevatedButton(
                                onPressed: () async {
                                  final data = {
                                    'nome': nomeCtrl.text,
                                    'isbn': isbnCtrl.text,
                                    'autor': autorCtrl.text,
                                    'n_patrimonio': patriCtrl.text,
                                    'quantidade':
                                        int.tryParse(qtdCtrl.text) ?? 1,
                                    'categoria': categoria,
                                    'estante_id': _estanteSelecionada!['id']
                                  };
                                  if (editando != null)
                                    await api.updateLivro(editando['id'], data);
                                  else
                                    await api.createLivro(data);
                                  if (mounted) Navigator.pop(ctx);
                                  await _recarregar();
                                  setState(() => _mensagem = editando != null
                                      ? 'Livro atualizado!'
                                      : 'Livro adicionado!');
                                },
                                child: const Text('Salvar'))),
                        const SizedBox(width: 8),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar')),
                      ]),
                      const SizedBox(height: 16),
                    ])))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavbar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_mensagem.isNotEmpty)
                Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(_mensagem,
                        style: const TextStyle(color: Color(0xFF16A34A)))),
              Expanded(
                  child: _tela == 'lista'
                      ? _buildSetores()
                      : _tela == 'setor'
                          ? _buildEstantes()
                          : _buildLivros()),
            ]),
    );
  }

  Widget _buildSetores() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Setores',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormSetor(),
                icon: const Icon(Icons.add),
                label: const Text('Novo Setor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _setores.isEmpty
              ? const Center(
                  child: Text('Nenhum setor cadastrado.',
                      style: TextStyle(color: Colors.grey)))
              : GridView.count(
                  padding: const EdgeInsets.all(12),
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: _setores.map<Widget>((s) {
                    return GestureDetector(
                      onTap: () => setState(() {
                        _setorSelecionado = s;
                        _tela = 'setor';
                      }),
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                                color: Color(0xFFE5E7EB), width: 2)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                          child: Text(s['nome'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                                '${(s['estantes'] ?? []).length}',
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2563EB))),
                                            const Text('estantes',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey)),
                                          ]),
                                    ]),
                                if (s['descricao'] != null &&
                                    s['descricao'] != '')
                                  Text(s['descricao'],
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF2563EB))),
                                const Spacer(),
                                Row(children: [
                                  GestureDetector(
                                      onTap: () => _mostrarFormSetor(s),
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFD97706),
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: const Text('Editar',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11)))),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                      onTap: () async {
                                        final conf = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                                    title: const Text(
                                                        'Remover setor?'),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: const Text(
                                                              'Cancelar')),
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          child: const Text(
                                                              'Remover',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red))),
                                                    ]));
                                        if (conf == true) {
                                          await api.deleteSetor(s['id']);
                                          await _recarregar();
                                        }
                                      },
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFDC2626),
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: const Text('Remover',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11)))),
                                ]),
                              ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildEstantes() {
    final estantes = (_setorSelecionado?['estantes'] ?? []) as List;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() {
                      _tela = 'lista';
                      _setorSelecionado = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estantes - ${_setorSelecionado?['nome'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormEstante(),
                icon: const Icon(Icons.add),
                label: const Text('Nova Estante'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: estantes.isEmpty
              ? const Center(
                  child: Text('Nenhuma estante neste setor.',
                      style: TextStyle(color: Colors.grey)))
              : GridView.count(
                  padding: const EdgeInsets.all(12),
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: estantes.map<Widget>((e) {
                    final qtd = _livrosDaEstanteById(e['id'] as int).length;
                    return GestureDetector(
                        onTap: () => setState(() {
                              _estanteSelecionada = e;
                              _tela = 'estante';
                            }),
                        child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                    color: Color(0xFFE5E7EB), width: 2)),
                            child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                                child: Text(e['nome'] ?? '',
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text('$qtd',
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                              0xFF2563EB))),
                                                  const Text('livros',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey)),
                                                ]),
                                          ]),
                                      if (e['descricao'] != null &&
                                          e['descricao'] != '')
                                        Text(e['descricao'],
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF2563EB))),
                                      const Spacer(),
                                      Row(children: [
                                        GestureDetector(
                                            onTap: () => _mostrarFormEstante(e),
                                            child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFD97706),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: const Text('Editar',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11)))),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                            onTap: () async {
                                              final conf = await showDialog<
                                                      bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                          title: const Text(
                                                              'Remover estante?'),
                                                          actions: [
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context,
                                                                        false),
                                                                child: const Text(
                                                                    'Cancelar')),
                                                            TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                        context,
                                                                        true),
                                                                child: const Text(
                                                                    'Remover',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .red)))
                                                          ]));
                                              if (conf == true) {
                                                await api
                                                    .deleteEstante(e['id']);
                                                await _recarregar();
                                              }
                                            },
                                            child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFDC2626),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: const Text('Remover',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11)))),
                                      ]),
                                    ]))));
                  }).toList()),
        ),
      ],
    );
  }

  Widget _buildLivros() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() {
                      _tela = 'setor';
                      _estanteSelecionada = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Livros - ${_estanteSelecionada?['nome'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _mostrarFormLivro(),
                icon: const Icon(Icons.add),
                label: const Text('Novo Livro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _livrosDaEstante.isEmpty
              ? const Center(
                  child: Text('Nenhum livro nesta estante.',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _livrosDaEstante.length,
                  itemBuilder: (_, i) {
                    final l = _livrosDaEstante[i];
                    final disponivel = l['status'] == 'disponivel';
                    return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(l['nome'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${l['autor'] ?? '-'} · ${l['categoria'] ?? ''}'),
                                Text(
                                    'Qtd: ${l['quantidade']} · Disponível: ${l['quantidade_disponivel']}',
                                    style: const TextStyle(fontSize: 12)),
                              ]),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: disponivel
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(l['status'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11))),
                            IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18, color: Color(0xFFD97706)),
                                onPressed: () => _mostrarFormLivro(l)),
                            IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Color(0xFFDC2626)),
                                onPressed: () async {
                                  final conf = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                              title:
                                                  const Text('Remover livro?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child:
                                                        const Text('Cancelar')),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: const Text('Remover',
                                                        style: TextStyle(
                                                            color: Colors.red)))
                                              ]));
                                  if (conf == true) {
                                    await api.deleteLivro(l['id']);
                                    await _recarregar();
                                  }
                                }),
                          ]),
                        ));
                  }),
        ),
      ],
    );
  }
}
