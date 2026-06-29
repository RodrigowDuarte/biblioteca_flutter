import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import '../widgets/app_navbar.dart';

class LivrosScreen extends StatefulWidget {
  const LivrosScreen({super.key});

  @override
  State<LivrosScreen> createState() => _LivrosScreenState();
}

class _LivrosScreenState extends State<LivrosScreen> {
  List<dynamic> livros = [];
  List<dynamic> categorias = [];
  List<dynamic> generos = [];
  List<dynamic> setores = [];
  List<dynamic> estantesFiltradas = [];

  bool loading = true;
  String busca = '';
  final Set<String> categoriasExpandidas = {};

  bool mostrarForm = false;
  Map? editandoLivro;
  final Map<String, dynamic> form = {};

  bool mostrarFormCategoria = false;
  Map? editandoCategoria;
  final TextEditingController nomeCategoriaCtrl = TextEditingController();
  final TextEditingController descricaoCategoriaCtrl = TextEditingController();

  bool mostrarFormGenero = false;
  Map? editandoGenero;
  final TextEditingController nomeGeneroCtrl = TextEditingController();
  final TextEditingController descricaoGeneroCtrl = TextEditingController();

  String mensagem = '';
  String erro = '';

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        api.getLivros(),
        api.getCategorias(),
        api.getGeneros(),
        api.getSetores(),
      ]);
      setState(() {
        livros = results[0];
        categorias = results[1];
        generos = results[2];
        setores = results[3];
        loading = false;
      });
    } catch (e) {
      setState(() {
        erro = 'Erro ao carregar dados: $e';
        loading = false;
      });
    }
  }

  List<dynamic> get filtrados {
    final b = busca.toLowerCase();
    return livros.where((l) {
      return (l['nome'] ?? '').toLowerCase().contains(b) ||
          (l['autor'] ?? '').toLowerCase().contains(b) ||
          (l['isbn'] ?? '').toString().contains(busca) ||
          (l['n_patrimonio'] ?? '').toString().contains(busca) ||
          (l['genero'] ?? '').toLowerCase().contains(b);
    }).toList();
  }

  List<dynamic> get categoriasComLivros {
    return categorias.where((c) {
      return livrosDaCategoria(c['nome']).isNotEmpty;
    }).toList();
  }

  List<dynamic> livrosDaCategoria(String nomeCat) {
    return filtrados.where((l) => l['categoria'] == nomeCat).toList();
  }

  int emprestadosDaCategoria(String nomeCat) {
    return livrosDaCategoria(nomeCat)
        .where((l) => l['status'] != 'disponivel')
        .length;
  }

  List<dynamic> get semCategoria {
    return filtrados.where((l) {
      return !categorias.any((c) => c['nome'] == l['categoria']);
    }).toList();
  }

  void toggleCategoria(String key) {
    setState(() {
      if (categoriasExpandidas.contains(key)) {
        categoriasExpandidas.remove(key);
      } else {
        categoriasExpandidas.add(key);
      }
    });
  }

  void abrirForm([Map? livro]) {
    setState(() {
      editandoLivro = livro;
      mostrarForm = true;
      form.clear();
      form.addAll({
        'nome': livro?['nome'] ?? '',
        'isbn': livro?['isbn'] ?? '',
        'autor': livro?['autor'] ?? '',
        'categoria': livro?['categoria'] ??
            (categorias.isNotEmpty ? categorias[0]['nome'] : ''),
        'genero': livro?['genero'] ?? '',
        'editora': livro?['editora'] ?? '',
        'ano_publicacao': livro?['ano_publicacao'] ?? '',
        'num_paginas': livro?['num_paginas'] ?? '',
        'quantidade': livro?['quantidade'] ?? 1,
        'n_patrimonio': livro?['n_patrimonio'] ?? '',
        'sinopse': livro?['sinopse'] ?? '',
        'observacao': livro?['observacao'] ?? '',
        'setor_id': livro?['estante']?['setor']?['id']?.toString() ?? '',
        'estante_id': livro?['estante_id']?.toString() ?? '',
      });
      final setorId = form['setor_id'];
      if (setorId != null && setorId.isNotEmpty) {
        final setor = setores.firstWhere(
          (s) => s['id'].toString() == setorId,
          orElse: () => null,
        );
        estantesFiltradas = (setor?['estantes'] ?? []) as List;
      } else {
        estantesFiltradas = [];
      }
    });
  }

  void resetForm() {
    form.clear();
    form.addAll({
      'nome': '',
      'isbn': '',
      'autor': '',
      'categoria': categorias.isNotEmpty ? categorias[0]['nome'] : '',
      'genero': '',
      'editora': '',
      'ano_publicacao': '',
      'num_paginas': '',
      'quantidade': 1,
      'n_patrimonio': '',
      'sinopse': '',
      'observacao': '',
      'setor_id': '',
      'estante_id': '',
    });
    estantesFiltradas = [];
    editandoLivro = null;
  }

  Future<void> salvarLivro() async {
    setState(() => erro = '');
    if (form['nome'].trim().isEmpty) {
      setState(() => erro = 'Título é obrigatório!');
      return;
    }
    if (form['n_patrimonio'].trim().isEmpty) {
      setState(() => erro = 'N. Patrimônio é obrigatório!');
      return;
    }

    final data = Map<String, dynamic>.from(form);
    // Converte campos numéricos para int se necessário
    if (data['quantidade'] is String) {
      data['quantidade'] = int.tryParse(data['quantidade']) ?? 1;
    }
    if (data['ano_publicacao'] is String) {
      data['ano_publicacao'] = data['ano_publicacao'].trim();
    }
    if (data['num_paginas'] is String) {
      data['num_paginas'] = data['num_paginas'].trim();
    }
    // Converte setor_id e estante_id para int ou null
    data['setor_id'] =
        data['setor_id'].isNotEmpty ? int.tryParse(data['setor_id']) : null;
    data['estante_id'] =
        data['estante_id'].isNotEmpty ? int.tryParse(data['estante_id']) : null;

    final res = editandoLivro != null
        ? await api.updateLivro(editandoLivro!['id'], data)
        : await api.createLivro(data);

    if (res['id'] != null) {
      setState(() {
        mensagem =
            editandoLivro != null ? 'Livro atualizado!' : 'Livro criado!';
        mostrarForm = false;
        resetForm();
      });
      await carregar();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => mensagem = '');
      });
    } else {
      setState(() => erro = res['message'] ?? 'Erro ao salvar livro');
    }
  }

  Future<void> removerLivro(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover livro?'),
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
    if (confirm == true) {
      await api.deleteLivro(id);
      await carregar();
    }
  }

  void abrirFormCategoria([Map? cat]) {
    setState(() {
      editandoCategoria = cat;
      mostrarFormCategoria = true;
      nomeCategoriaCtrl.text = cat?['nome'] ?? '';
      descricaoCategoriaCtrl.text = cat?['descricao'] ?? '';
    });
  }

  Future<void> salvarCategoria() async {
    setState(() => erro = '');
    final nome = nomeCategoriaCtrl.text.trim();
    if (nome.isEmpty) {
      setState(() => erro = 'Nome interno é obrigatório!');
      return;
    }
    final desc = descricaoCategoriaCtrl.text.trim() == ''
        ? nome
        : descricaoCategoriaCtrl.text.trim();

    final data = {'nome': nome, 'descricao': desc};
    final res = editandoCategoria != null
        ? await api.updateCategoria(editandoCategoria!['id'], data)
        : await api.createCategoria(data);

    if (res['id'] != null) {
      setState(() {
        mensagem = editandoCategoria != null
            ? 'Categoria "${res['descricao']}" atualizada!'
            : 'Categoria "${res['descricao']}" criada!';
        mostrarFormCategoria = false;
        editandoCategoria = null;
        nomeCategoriaCtrl.clear();
        descricaoCategoriaCtrl.clear();
      });
      await carregar();
      if (res['nome'] != null) {
        setState(() => categoriasExpandidas.add(res['nome']));
      }
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => mensagem = '');
      });
    } else {
      setState(() => erro = res['message'] ?? 'Erro ao salvar categoria');
    }
  }

  Future<void> removerCategoria(Map cat) async {
    final qtd = livros.where((l) => l['categoria'] == cat['nome']).length;
    if (qtd > 0) {
      setState(() =>
          erro = 'Não é possível remover: $qtd livro(s) com esta categoria.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover categoria?'),
        content: const Text(
            'Os livros não serão apagados, apenas a categoria será removida.'),
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
    if (confirm == true) {
      await api.deleteCategoria(cat['id']);
      await carregar();
    }
  }

  void abrirFormGenero([Map? gen]) {
    setState(() {
      editandoGenero = gen;
      mostrarFormGenero = true;
      nomeGeneroCtrl.text = gen?['nome'] ?? '';
      descricaoGeneroCtrl.text = gen?['descricao'] ?? '';
    });
  }

  Future<void> salvarGenero() async {
    setState(() => erro = '');
    final nome = nomeGeneroCtrl.text.trim();
    if (nome.isEmpty) {
      setState(() => erro = 'Nome interno é obrigatório!');
      return;
    }
    final desc = descricaoGeneroCtrl.text.trim() == ''
        ? nome
        : descricaoGeneroCtrl.text.trim();

    final data = {'nome': nome, 'descricao': desc};
    final res = editandoGenero != null
        ? await api.updateGenero(editandoGenero!['id'], data)
        : await api.createGenero(data);

    if (res['id'] != null) {
      setState(() {
        mensagem = editandoGenero != null
            ? 'Gênero "${res['descricao']}" atualizado!'
            : 'Gênero "${res['descricao']}" criado!';
        mostrarFormGenero = false;
        editandoGenero = null;
        nomeGeneroCtrl.clear();
        descricaoGeneroCtrl.clear();
      });
      await carregar();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => mensagem = '');
      });
    } else {
      setState(() => erro = res['message'] ?? 'Erro ao salvar gênero');
    }
  }

  Future<void> removerGenero(Map gen) async {
    final qtd = livros.where((l) => l['genero'] == gen['nome']).length;
    if (qtd > 0) {
      setState(() =>
          erro = 'Não é possível remover: $qtd livro(s) com este gênero.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover gênero?'),
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
    if (confirm == true) {
      await api.deleteGenero(gen['id']);
      await carregar();
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'disponivel' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (busca.isNotEmpty && categoriasExpandidas.isEmpty) {
      for (final c in categorias) {
        if (livrosDaCategoria(c['nome']).isNotEmpty) {
          categoriasExpandidas.add(c['nome']);
        }
      }
      if (semCategoria.isNotEmpty) {
        categoriasExpandidas.add('_outros');
      }
    }

    return Scaffold(
      appBar: const AppNavbar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Livros',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${livros.length} no total',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => abrirFormGenero(),
                            icon: const Icon(Icons.category, size: 16),
                            label: const Text('Gêneros'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => abrirFormCategoria(),
                            icon: const Icon(Icons.label, size: 16),
                            label: const Text('Categorias'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => abrirForm(),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Novo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (mensagem.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(mensagem,
                          style: const TextStyle(color: Colors.green)),
                    ),
                  if (erro.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          Text(erro, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 16),
                  if (mostrarFormCategoria) _buildCategoriaModal(),
                  if (mostrarFormGenero) _buildGeneroModal(),
                  if (mostrarForm) _buildLivroModal(),
                  TextField(
                    decoration: const InputDecoration(
                      hintText:
                          'Pesquisar por título, autor, ISBN ou patrimônio...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      setState(() {
                        busca = v;
                        if (v.isNotEmpty) {
                          for (final c in categorias) {
                            if (livrosDaCategoria(c['nome']).isNotEmpty) {
                              categoriasExpandidas.add(c['nome']);
                            }
                          }
                          if (semCategoria.isNotEmpty) {
                            categoriasExpandidas.add('_outros');
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (filtrados.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(48),
                      alignment: Alignment.center,
                      child: Text(
                        busca.isNotEmpty
                            ? 'Nenhum livro encontrado.'
                            : 'Nenhum livro cadastrado ainda.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Categorias',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...categoriasComLivros.map((cat) {
                          final nome = cat['nome'];
                          final livrosCat = livrosDaCategoria(nome);
                          final expandida = categoriasExpandidas.contains(nome);
                          final emprestados = emprestadosDaCategoria(nome);
                          return _buildCategoriaCard(
                            titulo: cat['descricao'] ?? nome,
                            count: livrosCat.length,
                            emprestados: emprestados,
                            expandida: expandida,
                            onToggle: () => toggleCategoria(nome),
                            livros: livrosCat,
                          );
                        }).toList(),
                        if (semCategoria.isNotEmpty)
                          _buildCategoriaCard(
                            titulo: 'Outros',
                            count: semCategoria.length,
                            emprestados: 0,
                            expandida: categoriasExpandidas.contains('_outros'),
                            onToggle: () => toggleCategoria('_outros'),
                            livros: semCategoria,
                            isOutros: true,
                          ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoriaCard({
    required String titulo,
    required int count,
    required int emprestados,
    required bool expandida,
    required VoidCallback onToggle,
    required List<dynamic> livros,
    bool isOutros = false,
  }) {
    final color = isOutros ? Colors.grey : Colors.blue;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            onTap: onToggle,
            tileColor: Colors.grey[50],
            leading: Container(
              width: 4,
              height: 30,
              color: color,
            ),
            title: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text('$count ${count == 1 ? 'item' : 'itens'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emprestados > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$emprestados emprestado${emprestados > 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(expandida ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (expandida)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        children: const [
                          SizedBox(
                              width: 120,
                              child: Text('Título',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 100,
                              child: Text('Autor',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 80,
                              child: Text('Gênero',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 120,
                              child: Text('Localização',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 40,
                              child: Text('Qtd',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 50,
                              child: Text('Disp.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 80,
                              child: Text('Status',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                          SizedBox(
                              width: 100,
                              child: Text('Ações',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    ...livros.map((livro) {
                      final localizacao = livro['estante'] != null
                          ? '${livro['estante']['setor']?['nome'] ?? ''} › ${livro['estante']['nome']}'
                          : '-';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                livro['nome'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(livro['autor'] ?? '-',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(livro['genero'] ?? '-',
                                  overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(localizacao,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text('${livro['quantidade'] ?? 0}'),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                  '${livro['quantidade_disponivel'] ?? 0}'),
                            ),
                            SizedBox(
                              width: 80,
                              child: _buildStatusBadge(
                                  livro['status'] ?? 'indisponivel'),
                            ),
                            SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => abrirForm(livro),
                                    color: Colors.orange,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => removerLivro(livro['id']),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLivroModal() {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 800,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editandoLivro != null ? 'Editar Livro' : 'Novo Livro',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildFormField('Título *', 'nome'),
                    _buildFormField('ISBN', 'isbn'),
                    _buildFormField('Autor', 'autor'),
                    _buildDropdownField('Categoria', 'categoria', categorias,
                        'nome', 'descricao'),
                    _buildDropdownField(
                        'Gênero', 'genero', generos, 'nome', 'descricao',
                        emptyOption: 'Sem gênero'),
                    _buildFormField('Editora', 'editora'),
                    _buildFormField('Ano', 'ano_publicacao', type: 'number'),
                    _buildFormField('Páginas', 'num_paginas', type: 'number'),
                    _buildFormField('Quantidade', 'quantidade', type: 'number'),
                    _buildFormField('N. Patrimônio *', 'n_patrimonio'),
                    _buildSetorEstanteFields(),
                    _buildFormField('Sinopse', 'sinopse', maxLines: 3),
                    _buildFormField('Observação', 'observacao', maxLines: 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      mostrarForm = false;
                      resetForm();
                    });
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: salvarLivro,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(String label, String key,
      {String type = 'text', int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: form[key]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType:
            type == 'number' ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        onChanged: (v) => form[key] = v,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String key,
    List<dynamic> items,
    String valueKey,
    String displayKey, {
    String? emptyOption,
  }) {
    final currentValue = form[key]?.toString() ?? '';
    final options = items.map((e) => e[valueKey].toString()).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: currentValue.isNotEmpty && options.contains(currentValue)
            ? currentValue
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          if (emptyOption != null)
            DropdownMenuItem(value: '', child: Text(emptyOption)),
          ...items.map((e) {
            final value = e[valueKey].toString();
            final display = e[displayKey]?.toString() ?? value;
            return DropdownMenuItem(value: value, child: Text(display));
          }),
        ],
        onChanged: (v) => setState(() {
          form[key] = v ?? '';
          if (key == 'setor_id') {
            final setor = setores.firstWhere(
              (s) => s['id'].toString() == v,
              orElse: () => null,
            );
            estantesFiltradas = (setor?['estantes'] ?? []) as List;
            form['estante_id'] = '';
          }
        }),
      ),
    );
  }

  Widget _buildSetorEstanteFields() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdownField(
            'Setor',
            'setor_id',
            setores,
            'id',
            'nome',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDropdownField(
            'Estante',
            'estante_id',
            estantesFiltradas,
            'id',
            'nome',
            emptyOption: 'Sem estante',
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriaModal() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  editandoCategoria != null
                      ? 'Editar Categoria'
                      : 'Gerenciar Categorias',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      mostrarFormCategoria = false;
                      editandoCategoria = null;
                      nomeCategoriaCtrl.clear();
                      descricaoCategoriaCtrl.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nomeCategoriaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome interno *',
                            hintText: 'Ex: manual, apostila...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          enabled: editandoCategoria == null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: descricaoCategoriaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome de exibição',
                            hintText: 'Ex: Manual, Apostila...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: salvarCategoria,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        child: Text(editandoCategoria != null
                            ? 'Salvar alteração'
                            : 'Criar categoria'),
                      ),
                      if (editandoCategoria != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              editandoCategoria = null;
                              nomeCategoriaCtrl.clear();
                              descricaoCategoriaCtrl.clear();
                            });
                          },
                          child: const Text('Cancelar edição'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Categorias cadastradas',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: categorias.map((cat) {
                  final qtd =
                      livros.where((l) => l['categoria'] == cat['nome']).length;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 150,
                            child: Text(cat['descricao'] ?? cat['nome'])),
                        SizedBox(width: 120, child: Text(cat['nome'] ?? '')),
                        SizedBox(width: 60, child: Text('$qtd')),
                        SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => abrirFormCategoria(cat),
                                color: Colors.orange,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: qtd > 0
                                    ? null
                                    : () => removerCategoria(cat),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneroModal() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  editandoGenero != null
                      ? 'Editar Gênero'
                      : 'Gerenciar Gêneros',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      mostrarFormGenero = false;
                      editandoGenero = null;
                      nomeGeneroCtrl.clear();
                      descricaoGeneroCtrl.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nomeGeneroCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome interno *',
                            hintText: 'Ex: ficcao, thriller...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          enabled: editandoGenero == null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: descricaoGeneroCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome de exibição',
                            hintText: 'Ex: Ficção, Thriller...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: salvarGenero,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                        ),
                        child: Text(editandoGenero != null
                            ? 'Salvar alteração'
                            : 'Criar gênero'),
                      ),
                      if (editandoGenero != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              editandoGenero = null;
                              nomeGeneroCtrl.clear();
                              descricaoGeneroCtrl.clear();
                            });
                          },
                          child: const Text('Cancelar edição'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Gêneros cadastrados',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: generos.map((gen) {
                  final qtd =
                      livros.where((l) => l['genero'] == gen['nome']).length;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 150,
                            child: Text(gen['descricao'] ?? gen['nome'])),
                        SizedBox(width: 120, child: Text(gen['nome'] ?? '')),
                        SizedBox(width: 60, child: Text('$qtd')),
                        SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => abrirFormGenero(gen),
                                color: Colors.orange,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed:
                                    qtd > 0 ? null : () => removerGenero(gen),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
