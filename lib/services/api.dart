import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://127.0.0.1:8000/api';

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<void> setToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

Future<void> removeToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
}

Future<Map<String, String>> getHeaders() async {
  final token = await getToken();
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

Future<dynamic> request(String endpoint,
    {String method = 'GET', Map<String, dynamic>? body}) async {
  final headers = await getHeaders();
  final uri = Uri.parse('$baseUrl$endpoint');

  print("URL: $uri");
  print("METHOD: $method");
  print("BODY: $body");

  http.Response response;

  try {
    switch (method) {
      case 'POST':
        response =
            await http.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PUT':
        response =
            await http.put(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        response = await http.get(uri, headers: headers);
    }

    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: ${response.body}");

    if (response.statusCode == 401) {
      await removeToken();
      return {'_unauthorized': true};
    }

    final decoded = utf8.decode(response.bodyBytes);
    return jsonDecode(decoded);
  } catch (e) {
    print("ERRO NA REQUISIÇÃO: $e");
    rethrow;
  }
}

// Auth
Future<dynamic> login(String email, String password) => request('/login',
    method: 'POST', body: {'email': email, 'password': password});

// Alunos
Future<dynamic> getAlunos() => request('/alunos');
Future<dynamic> createAluno(Map<String, dynamic> data) =>
    request('/alunos', method: 'POST', body: data);
Future<dynamic> updateAluno(int id, Map<String, dynamic> data) =>
    request('/alunos/$id', method: 'PUT', body: data);
Future<dynamic> deleteAluno(int id) => request('/alunos/$id', method: 'DELETE');

// Turmas
Future<dynamic> getTurmas() => request('/turmas');
Future<dynamic> createTurma(Map<String, dynamic> data) =>
    request('/turmas', method: 'POST', body: data);
Future<dynamic> updateTurma(int id, Map<String, dynamic> data) =>
    request('/turmas/$id', method: 'PUT', body: data);
Future<dynamic> deleteTurma(int id) => request('/turmas/$id', method: 'DELETE');
Future<dynamic> getMembrosDaTurma(int id) => request('/turmas/$id/membros');

// Livros
Future<dynamic> getLivros() => request('/livros');
Future<dynamic> createLivro(Map<String, dynamic> data) =>
    request('/livros', method: 'POST', body: data);
Future<dynamic> updateLivro(int id, Map<String, dynamic> data) =>
    request('/livros/$id', method: 'PUT', body: data);
Future<dynamic> deleteLivro(int id) => request('/livros/$id', method: 'DELETE');

// Categorias
Future<dynamic> getCategorias() => request('/categorias');
Future<dynamic> createCategoria(Map<String, dynamic> data) =>
    request('/categorias', method: 'POST', body: data);
Future<dynamic> updateCategoria(int id, Map<String, dynamic> data) =>
    request('/categorias/$id', method: 'PUT', body: data);
Future<dynamic> deleteCategoria(int id) =>
    request('/categorias/$id', method: 'DELETE');

// Generos
Future<dynamic> getGeneros() => request('/generos');
Future<dynamic> createGenero(Map<String, dynamic> data) =>
    request('/generos', method: 'POST', body: data);
Future<dynamic> updateGenero(int id, Map<String, dynamic> data) =>
    request('/generos/$id', method: 'PUT', body: data);
Future<dynamic> deleteGenero(int id) =>
    request('/generos/$id', method: 'DELETE');

// Emprestimos
Future<dynamic> getEmprestimos() => request('/emprestimos');
Future<dynamic> emprestar(Map<String, dynamic> data) =>
    request('/emprestar', method: 'POST', body: data);
Future<dynamic> devolver(Map<String, dynamic> data) =>
    request('/devolver', method: 'POST', body: data);

// Historico
Future<dynamic> getHistorico() => request('/historico');
Future<dynamic> deletarHistorico(int id) =>
    request('/historico/$id', method: 'DELETE');
Future<dynamic> limparHistorico() =>
    request('/historico/limpar', method: 'DELETE');

// Inadimplentes
Future<dynamic> getInadimplentes() => request('/inadimplentes');

// Localizacao
Future<dynamic> getSetores() => request('/setores');
Future<dynamic> createSetor(Map<String, dynamic> data) =>
    request('/setores', method: 'POST', body: data);
Future<dynamic> updateSetor(int id, Map<String, dynamic> data) =>
    request('/setores/$id', method: 'PUT', body: data);
Future<dynamic> deleteSetor(int id) =>
    request('/setores/$id', method: 'DELETE');

Future<dynamic> getEstantes() => request('/estantes');
Future<dynamic> createEstante(Map<String, dynamic> data) =>
    request('/estantes', method: 'POST', body: data);
Future<dynamic> updateEstante(int id, Map<String, dynamic> data) =>
    request('/estantes/$id', method: 'PUT', body: data);
Future<dynamic> deleteEstante(int id) =>
    request('/estantes/$id', method: 'DELETE');
