// chamadas para a api
import 'dart:convert';

import 'package:http/http.dart' as http;

const String enderecoApi = 'http://127.0.0.1:8080';

Future<Map<String, dynamic>> chamarApi(
  String rota,
  String token,
  Map<String, dynamic> dados,
) async {
  try {
    Uri endereco = Uri.parse('$enderecoApi/$rota');
    Map<String, String> cabecalhos = {
      'Content-Type': 'application/json; charset=utf-8',
      'token': token,
    };

    http.Response resposta;
    if (dados.isEmpty) {
      resposta = await http.get(endereco, headers: cabecalhos);
    } else {
      resposta = await http.post(endereco, headers: cabecalhos, body: jsonEncode(dados));
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  } catch (erro) {
    return {'STATUS': 0, 'MSG': 'Não foi possível falar com a API. Ela está ligada?'};
  }
}
