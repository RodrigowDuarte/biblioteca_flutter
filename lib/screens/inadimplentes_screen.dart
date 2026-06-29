// screens/inadimplentes_screen.dart
import 'package:flutter/material.dart';
import '../services/api.dart' as api;
import '../widgets/app_navbar.dart';

class InadimplentesScreen extends StatefulWidget {
  const InadimplentesScreen({super.key});
  @override
  State<InadimplentesScreen> createState() => _InadimplentesScreenState();
}

class _InadimplentesScreenState extends State<InadimplentesScreen> {
  List _inadimplentes = [];
  List _turmas = [];
  bool _loading = true;
  String _busca = '';
  String _ordenacao = 'atraso_desc';
  Set<String> _turmasExpandidas = {};
  bool _geralExpandida = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final results =
        await Future.wait([api.getInadimplentes(), api.getTurmas()]);
    setState(() {
      _inadimplentes = results[0] as List;
      _turmas = results[1] as List;
      _loading = false;
    });
  }

  int _diasAtraso(String? data) {
    if (data == null) return 0;
    return DateTime.now().difference(DateTime.parse(data)).inDays;
  }

  List get _filtrados {
    final base = _inadimplentes
        .where((i) =>
            (i['aluno']?['nome'] ?? '')
                .toLowerCase()
                .contains(_busca.toLowerCase()) ||
            (i['aluno']?['turma'] ?? '')
                .toLowerCase()
                .contains(_busca.toLowerCase()) ||
            (i['livro']?['nome'] ?? '')
                .toLowerCase()
                .contains(_busca.toLowerCase()))
        .toList();
    base.sort((a, b) {
      final diasA = _diasAtraso(a['data_prevista_devolucao']);
      final diasB = _diasAtraso(b['data_prevista_devolucao']);
      switch (_ordenacao) {
        case 'atraso_asc':
          return diasA.compareTo(diasB);
        case 'nome':
          return (a['aluno']?['nome'] ?? '')
              .compareTo(b['aluno']?['nome'] ?? '');
        case 'turma':
          return (a['aluno']?['turma'] ?? '')
              .compareTo(b['aluno']?['turma'] ?? '');
        default:
          return diasB.compareTo(diasA);
      }
    });
    return base;
  }

  Map<String, List> get _porTurma {
    final g = <String, List>{};
    for (final t in _turmas) {
      final items = _inadimplentes
          .where((i) => i['aluno']?['turma'] == t['nome'])
          .toList();
      if (items.isNotEmpty) g[t['nome']] = items;
    }
    final sem = _inadimplentes
        .where(
            (i) => i['aluno']?['turma'] == null || i['aluno']?['turma'] == '')
        .toList();
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
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      TextField(
                          decoration: const InputDecoration(
                              hintText:
                                  'Pesquisar por membro, turma ou livro...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true),
                          onChanged: (v) => setState(() => _busca = v)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            const Text('Ordenar: ',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            ...[
                              ['atraso_desc', 'Maior atraso'],
                              ['atraso_asc', 'Menor atraso'],
                              ['nome', 'Nome'],
                              ['turma', 'Turma']
                            ].map((o) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _ordenacao = o[0]),
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: _ordenacao == o[0]
                                                ? const Color(0xFFDC2626)
                                                : Colors.white,
                                            border: Border.all(
                                                color: _ordenacao == o[0]
                                                    ? const Color(0xFFDC2626)
                                                    : Colors.grey.shade300),
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: Text(o[1],
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: _ordenacao == o[0] ? Colors.white : Colors.black87)))))),
                          ])),
                    ])),
                Expanded(
                    child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                      // Geral
                      Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFFFCA5A5))),
                          child: Column(children: [
                            ListTile(
                              tileColor: const Color(0xFFFFF5F5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: const Radius.circular(8),
                                      bottom: _geralExpandida
                                          ? Radius.zero
                                          : const Radius.circular(8))),
                              title: const Text('Todos os Inadimplentes',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFDC2626),
                                            borderRadius:
                                                BorderRadius.circular(999)),
                                        child: Text(
                                            '${_filtrados.length} registros',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11))),
                                    Icon(_geralExpandida
                                        ? Icons.expand_less
                                        : Icons.expand_more),
                                  ]),
                              onTap: () => setState(
                                  () => _geralExpandida = !_geralExpandida),
                            ),
                            if (_geralExpandida)
                              ..._filtrados.map((i) => _inadCard(i)),
                          ])),
                      const SizedBox(height: 12),
                      const Text('Inadimplentes por Turma',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._porTurma.entries.map((entry) {
                        final nome = entry.key;
                        final items = entry.value;
                        final expandida = _turmasExpandidas.contains(nome);
                        final maxAtraso = items
                            .map((i) =>
                                _diasAtraso(i['data_prevista_devolucao']))
                            .reduce((a, b) => a > b ? a : b);
                        return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side:
                                    const BorderSide(color: Color(0xFFFCA5A5))),
                            child: Column(children: [
                              ListTile(
                                tileColor: const Color(0xFFFFF5F5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: const Radius.circular(8),
                                        bottom: expandida
                                            ? Radius.zero
                                            : const Radius.circular(8))),
                                title: Text(nome,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${items.length} inadimplente${items.length != 1 ? 's' : ''} · máx $maxAtraso dias'),
                                trailing: Icon(expandida
                                    ? Icons.expand_less
                                    : Icons.expand_more),
                                onTap: () => setState(() => expandida
                                    ? _turmasExpandidas.remove(nome)
                                    : _turmasExpandidas.add(nome)),
                              ),
                              if (expandida) ...items.map((i) => _inadCard(i)),
                            ]));
                      }),
                      const SizedBox(height: 16),
                    ])),
              ]),
            ),
    );
  }

  Widget _inadCard(Map i) {
    final dias = _diasAtraso(i['data_prevista_devolucao']);
    final data = i['data_prevista_devolucao'] != null
        ? DateTime.tryParse(i['data_prevista_devolucao'])?.toLocal()
        : null;
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            border: Border.all(color: const Color(0xFFFEE2E2)),
            borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(i['aluno']?['nome'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(i['livro']?['nome'] ?? '',
                    style: const TextStyle(fontSize: 13)),
                if (data != null)
                  Text('Devolver até: ${data.day}/${data.month}/${data.year}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDC2626))),
                Text('${i['aluno']?['turma'] ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(999)),
              child: Text('$dias ${dias == 1 ? 'dia' : 'dias'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12))),
        ]));
  }
}
