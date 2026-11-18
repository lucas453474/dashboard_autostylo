// Servidor estático bem pequeno: entrega os arquivos da pasta web/ (o app Flutter
// compilado com "flutter build web") em http://localhost:5055.
// Serve só para o PC da faculdade, que não tem Flutter. Não faz parte da API.
// Compilar: dart compile exe bin/site.dart -o ../pacote_facul/site.exe
import 'dart:io';

const int portaSite = 5055;
const String pastaSite = 'web';

// Tipo de cada arquivo, para o navegador saber o que está recebendo
String tipoDoArquivo(String caminho) {
  List<String> partes = caminho.split('.');
  String extensao = partes[partes.length - 1].toLowerCase();
  switch (extensao) {
    case 'html':
      return 'text/html; charset=utf-8';
    case 'js':
    case 'mjs':
      return 'application/javascript';
    case 'json':
      return 'application/json';
    case 'css':
      return 'text/css';
    case 'wasm':
      return 'application/wasm';
    case 'png':
      return 'image/png';
    case 'ico':
      return 'image/x-icon';
    case 'otf':
      return 'font/otf';
    case 'ttf':
      return 'font/ttf';
  }
  return 'application/octet-stream';
}

// Responde um pedido do navegador com o arquivo pedido
Future<void> responder(HttpRequest pedido) async {
  String caminho = pedido.uri.path;

  // "/" é a página inicial
  if (caminho == '/') {
    caminho = '/index.html';
  }

  // Segurança: não deixa sair da pasta web/ (ex.: /../config.txt)
  if (caminho.contains('..')) {
    pedido.response.statusCode = 403;
    await pedido.response.close();
    return;
  }

  // Arquivo não existe: 404
  File arquivo = File('$pastaSite$caminho');
  if (!arquivo.existsSync()) {
    pedido.response.statusCode = 404;
    await pedido.response.close();
    return;
  }

  // Manda o arquivo
  pedido.response.headers.set('Content-Type', tipoDoArquivo(caminho));
  await pedido.response.addStream(arquivo.openRead());
  await pedido.response.close();
}

Future<void> main() async {
  // Verifica se a pasta web/ está ao lado do site.exe
  if (!Directory(pastaSite).existsSync()) {
    print('ERRO: pasta "$pastaSite" não encontrada.');
    print('Procurei em: ${Directory.current.path}\\$pastaSite');
    print('O site.exe precisa estar na mesma pasta que a pasta web\\.');
    exitCode = 1;
    return;
  }

  // Liga o servidor (só nesta máquina: loopback)
  HttpServer servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, portaSite);
  print('Site rodando em http://localhost:$portaSite (pasta: $pastaSite)');
  print('Deixe esta janela aberta durante a apresentação.');

  // Atende os pedidos um por um, enquanto o programa estiver aberto
  await for (HttpRequest pedido in servidor) {
    try {
      await responder(pedido);
    } catch (erro) {
      print('Erro ao responder ${pedido.uri.path}: $erro');
    }
  }
}
