// conexao com o mysql
import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

String bancoHost = '';
int bancoPorta = 3306;
String bancoUsuario = '';
String bancoSenha = '';
String bancoNome = '';

bool lerConfig() {
  File arquivo = File('config.txt');
  if (!arquivo.existsSync()) {
    print('ERRO: config.txt não encontrado em ${Directory.current.path}');
    print('Formato: host;porta;usuario;senha;banco (veja o config_exemplo.txt)');
    return false;
  }

  List<String> dados = arquivo.readAsStringSync().trim().split(';');
  if (dados.length != 5) {
    print('ERRO: o config.txt precisa ter 5 partes: host;porta;usuario;senha;banco');
    return false;
  }

  bancoHost = dados[0].trim();
  bancoPorta = int.parse(dados[1].trim());
  bancoUsuario = dados[2].trim();
  bancoSenha = dados[3];
  bancoNome = dados[4].trim();
  print('Configuração lida: $bancoUsuario@$bancoHost:$bancoPorta/$bancoNome');
  return true;
}

Future<MySQLConnection> abrirConexao() async {
  MySQLConnection conexao = await MySQLConnection.createConnection(
    host: bancoHost,
    port: bancoPorta,
    userName: bancoUsuario,
    password: bancoSenha,
    databaseName: bancoNome,
    collation: 'utf8mb4_unicode_ci',
  );
  await conexao.connect();
  return conexao;
}
