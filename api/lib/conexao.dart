import 'package:mysql_client/mysql_client.dart';

import 'config.dart';

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
