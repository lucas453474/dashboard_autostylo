// rotas da api
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:api/conexao.dart';
import 'package:api/funcoes.dart';
import 'package:api/limite.dart';

Map<String, String> cabecalhos = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, token',
  'Content-Type': 'application/json; charset=utf-8',
};

Response responder(Map<String, dynamic> dados, int codigo) {
  return Response(codigo, body: jsonEncode(dados), headers: cabecalhos, encoding: utf8);
}

Future<Map<String, dynamic>> lerCorpo(Request requisicao) async {
  try {
    String corpo = await requisicao.readAsString();
    Map<String, dynamic> dados = jsonDecode(corpo);
    return dados;
  } catch (erro) {
    return {};
  }
}

Future<Response> tratarRequisicao(Request requisicao) async {
  String metodo = requisicao.method;
  String rota = requisicao.url.path;

  if (metodo == 'OPTIONS') {
    return Response.ok('', headers: cabecalhos);
  }

  HttpConnectionInfo info = requisicao.context['shelf.io.connection_info'] as HttpConnectionInfo;
  String ip = info.remoteAddress.address;
  if (passouDoLimite(contagemGeral, inicioGeral, ip, 60)) {
    return responder({'STATUS': 0, 'MSG': 'Muitas requisições. Espere 1 minuto.'}, 429);
  }

  if (metodo == 'POST' && rota == 'login') {
    if (passouDoLimite(contagemLogin, inicioLogin, ip, 5)) {
      return responder({'STATUS': 0, 'MSG': 'Muitas tentativas de login. Espere 1 minuto.'}, 429);
    }
    Map<String, dynamic> dados = await lerCorpo(requisicao);
    Map<String, dynamic> resposta = await fazerLogin(
      lerTexto(dados, 'login'),
      lerTexto(dados, 'senha'),
    );
    return responder(resposta, 200);
  }

  String? token = requisicao.headers['token'];
  if (token == null || !tokensValidos.contains(token)) {
    return responder({'STATUS': 0, 'MSG': 'Faça o login primeiro.'}, 401);
  }

  if (metodo == 'GET' && rota == 'atendimentos') {
    Map<String, dynamic> resposta = await listaAtendimentos();
    return responder(resposta, 200);
  }

  if (metodo == 'POST' && rota == 'cadastrar') {
    Map<String, dynamic> dados = await lerCorpo(requisicao);
    Map<String, dynamic> resposta = await cadastrarAtendimento(dados);
    return responder(resposta, 200);
  }

  return responder({'STATUS': 0, 'MSG': 'Rota não encontrada.'}, 404);
}

Future<void> main() async {
  if (!lerConfig()) {
    exitCode = 1;
    return;
  }
  await shelf_io.serve(tratarRequisicao, '127.0.0.1', 8080);
  print('API rodando em http://127.0.0.1:8080');
}
