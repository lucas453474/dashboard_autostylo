import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:api/conexao.dart';
import 'package:api/funcoes.dart';
import 'package:api/limite.dart';

// Porta em que a API vai rodar (o app procura a API em http://127.0.0.1:8080)
const int apiPorta = 8080;

// Cabeçalhos de CORS: deixam o app (que roda em outra porta) falar com a API
Map<String, String> cabecalhos = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, token',
  'Content-Type': 'application/json; charset=utf-8',
};

// Transforma o Map em JSON e devolve a resposta
Response responder(Map<String, dynamic> dados, int codigo) {
  return Response(codigo, body: jsonEncode(dados), headers: cabecalhos, encoding: utf8);
}

// Descobre o IP de quem fez a requisição
String pegarIp(Request requisicao) {
  HttpConnectionInfo? info =
      requisicao.context['shelf.io.connection_info'] as HttpConnectionInfo?;
  if (info == null) {
    return 'desconhecido';
  }
  return info.remoteAddress.address;
}

// Lê o corpo da requisição (JSON) e transforma em Map
Future<Map<String, dynamic>> lerCorpo(Request requisicao) async {
  try {
    String corpo = await requisicao.readAsString();
    Map<String, dynamic> dados = jsonDecode(corpo);
    return dados;
  } catch (erro) {
    return {};
  }
}

// Recebe TODAS as requisições e decide o que fazer pela rota
Future<Response> tratarRequisicao(Request requisicao) async {
  String metodo = requisicao.method;
  String rota = requisicao.url.path;

  // O navegador manda um OPTIONS antes do POST (CORS): só responde ok
  if (metodo == 'OPTIONS') {
    return Response.ok('', headers: cabecalhos);
  }

  // Limite geral: 60 requisições por minuto por IP
  String ip = pegarIp(requisicao);
  if (limiteGeralEstourado(ip)) {
    return responder({'STATUS': 0, 'MSG': 'Muitas requisições. Espere 1 minuto.'}, 429);
  }

  // POST /login
  if (metodo == 'POST' && rota == 'login') {
    // Limite de login: 5 tentativas por minuto por IP
    if (limiteLoginEstourado(ip)) {
      return responder(
        {'STATUS': 0, 'MSG': 'Muitas tentativas de login. Espere 1 minuto.'},
        429,
      );
    }
    Map<String, dynamic> dados = await lerCorpo(requisicao);
    Map<String, dynamic> resposta = await fazerLogin(
      lerTexto(dados, 'login'),
      lerTexto(dados, 'senha'),
    );
    return responder(resposta, 200);
  }

  // As outras rotas precisam do token do login
  String? token = requisicao.headers['token'];
  if (token == null || !tokenValido(token)) {
    return responder({'STATUS': 0, 'MSG': 'Faça o login primeiro.'}, 401);
  }

  // GET /atendimentos
  if (metodo == 'GET' && rota == 'atendimentos') {
    Map<String, dynamic> resposta = await listaAtendimentos();
    return responder(resposta, 200);
  }

  // POST /cadastrar
  if (metodo == 'POST' && rota == 'cadastrar') {
    Map<String, dynamic> dados = await lerCorpo(requisicao);
    Map<String, dynamic> resposta = await cadastrarAtendimento(dados);
    return responder(resposta, 200);
  }

  // Rota que não existe
  return responder({'STATUS': 0, 'MSG': 'Rota não encontrada.'}, 404);
}

// Liga o servidor
Future<void> main() async {
  // Sem config.txt (ou com ele errado) a API não liga: mostra a mensagem e para
  if (!lerConfig()) {
    exitCode = 1;
    return;
  }

  HttpServer servidor = await shelf_io.serve(tratarRequisicao, '127.0.0.1', apiPorta);
  print('API rodando em http://${servidor.address.host}:${servidor.port}');
}
