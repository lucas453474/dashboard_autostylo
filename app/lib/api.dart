import 'dart:convert';

import 'package:http/http.dart' as http;

// Endereço da API (na Fase 3 vira o endereço do Render)
const String enderecoApi = 'http://127.0.0.1:8080';

// Mensagem quando a API está desligada ou fora do ar
Map<String, dynamic> semConexao = {
  'STATUS': 0,
  'MSG': 'Não foi possível falar com a API. Ela está ligada?',
};

// Lê a resposta da API (JSON com STATUS e MSG) e transforma em Map
Map<String, dynamic> lerResposta(http.Response resposta) {
  Map<String, dynamic> dados = jsonDecode(utf8.decode(resposta.bodyBytes));
  return dados;
}

// POST /login -> devolve STATUS, MSG e token
// async/await: a resposta da API demora, então a função devolve um Future
Future<Map<String, dynamic>> fazerLogin(String login, String senha) async {
  try {
    http.Response resposta = await http.post(
      Uri.parse('$enderecoApi/login'),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'login': login, 'senha': senha}),
    );
    return lerResposta(resposta);
  } catch (erro) {
    return semConexao;
  }
}

// GET /atendimentos -> devolve STATUS, MSG e DADOS (lista de atendimentos)
Future<Map<String, dynamic>> buscarAtendimentos(String token) async {
  try {
    http.Response resposta = await http.get(
      Uri.parse('$enderecoApi/atendimentos'),
      headers: {'token': token},
    );
    return lerResposta(resposta);
  } catch (erro) {
    return semConexao;
  }
}

// POST /cadastrar -> grava um novo atendimento
Future<Map<String, dynamic>> cadastrarAtendimento(String token, Map<String, dynamic> dados) async {
  try {
    http.Response resposta = await http.post(
      Uri.parse('$enderecoApi/cadastrar'),
      headers: {'Content-Type': 'application/json; charset=utf-8', 'token': token},
      body: jsonEncode(dados),
    );
    return lerResposta(resposta);
  } catch (erro) {
    return semConexao;
  }
}
