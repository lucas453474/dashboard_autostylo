// servidor do site compilado para o pc da faculdade
import 'dart:io';

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
    case 'wasm':
      return 'application/wasm';
    case 'png':
      return 'image/png';
    case 'otf':
      return 'font/otf';
    case 'ttf':
      return 'font/ttf';
  }
  return 'application/octet-stream';
}

Future<void> responder(HttpRequest pedido) async {
  String caminho = pedido.uri.path;
  if (caminho == '/') {
    caminho = '/index.html';
  }

  File arquivo = File('web$caminho');
  if (caminho.contains('..') || !arquivo.existsSync()) {
    pedido.response.statusCode = 404;
    await pedido.response.close();
    return;
  }

  pedido.response.headers.set('Content-Type', tipoDoArquivo(caminho));
  await pedido.response.addStream(arquivo.openRead());
  await pedido.response.close();
}

Future<void> main() async {
  if (!Directory('web').existsSync()) {
    print('ERRO: a pasta web precisa estar ao lado do site.exe');
    exitCode = 1;
    return;
  }

  HttpServer servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 8000);
  print('Site rodando em http://localhost:8000');
  print('Deixe esta janela aberta durante a apresentação.');

  await for (HttpRequest pedido in servidor) {
    try {
      await responder(pedido);
    } catch (erro) {
      print('Erro ao responder ${pedido.uri.path}: $erro');
    }
  }
}
