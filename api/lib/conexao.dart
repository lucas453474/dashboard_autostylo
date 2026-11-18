import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

// Nome do arquivo de configuração (fica na mesma pasta de onde a API é aberta)
const String arquivoConfig = 'config.txt';

// Dados de conexão com o MySQL (preenchidos pelo lerConfig, quando a API liga)
String bancoHost = '';
int bancoPorta = 3306;
String bancoUsuario = '';
String bancoSenha = '';
String bancoNome = '';

// Lê o config.txt (uma linha só: host;porta;usuario;senha;banco)
// Mesma ideia da aula de arquivos: File, existsSync, readAsLinesSync e split(';')
bool lerConfig() {
  File arquivo = File(arquivoConfig);

  // Verifica se o arquivo existe
  if (!arquivo.existsSync()) {
    print('ERRO: arquivo $arquivoConfig não encontrado.');
    print('Procurei em: ${Directory.current.path}\\$arquivoConfig');
    print('Crie esse arquivo com uma linha só, no formato:');
    print('  host;porta;usuario;senha;banco');
    print('Exemplo (veja o config_exemplo.txt):');
    print('  127.0.0.1;3306;root;SUA_SENHA;auto_stylo_bi');
    return false;
  }

  // Pega a primeira linha que não está vazia
  List<String> linhas = arquivo.readAsLinesSync();
  String linha = '';
  for (String atual in linhas) {
    // Tira o "BOM" que o Bloco de Notas às vezes coloca no começo do arquivo
    String limpa = atual.replaceAll('﻿', '').trim();
    if (limpa.isNotEmpty) {
      linha = limpa;
      break;
    }
  }

  // Confere se a linha tem as 5 partes
  List<String> dados = linha.split(';');
  if (dados.length != 5) {
    print('ERRO: o $arquivoConfig precisa ter 5 partes separadas por ";".');
    print('Formato: host;porta;usuario;senha;banco');
    print('Encontrei ${dados.length} parte(s).');
    return false;
  }

  // Confere se a porta é um número
  int? porta = int.tryParse(dados[1].trim());
  if (porta == null) {
    print('ERRO: a porta no $arquivoConfig precisa ser um número (ex.: 3306).');
    return false;
  }

  // Guarda os dados nas variáveis
  bancoHost = dados[0].trim();
  bancoPorta = porta;
  bancoUsuario = dados[2].trim();
  bancoSenha = dados[3];
  bancoNome = dados[4].trim();
  print('Configuração lida: $bancoUsuario@$bancoHost:$bancoPorta/$bancoNome');
  return true;
}

// Abre uma conexão nova com o MySQL (igual ao meu conexao.php).
// Sempre em utf8mb4, porque os dados têm acento (CARTÃO, Capô, Múltiplas áreas).
// async/await: conectar no banco demora, então a função devolve um Future.
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
