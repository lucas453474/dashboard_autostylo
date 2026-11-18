// Um atendimento da funilaria (uma linha da Fato_Servicos já com os JOINs feitos)
class Atendimento {
  String id;
  String cliente;
  int clienteId;
  String placa;
  String modelo;
  String descricao;
  String area;
  String formaPagamento;
  double valor;
  int diasReparo;
  String dataEntrada;
  String anoMesEntrada;
  String dataPagamento;
  String anoMesPagamento;
  int anoEntrada;

  Atendimento(
    this.id,
    this.cliente,
    this.clienteId,
    this.placa,
    this.modelo,
    this.descricao,
    this.area,
    this.formaPagamento,
    this.valor,
    this.diasReparo,
    this.dataEntrada,
    this.anoMesEntrada,
    this.dataPagamento,
    this.anoMesPagamento,
    this.anoEntrada,
  );
}

// Transforma o Map que veio do JSON da API em um Atendimento
// (o Map só existe na "fronteira"; daqui pra frente usamos a classe)
Atendimento criarAtendimento(Map<String, dynamic> dados) {
  return Atendimento(
    dados['id'].toString(),
    dados['cliente'].toString(),
    int.parse(dados['clienteId'].toString()),
    dados['placa'].toString(),
    dados['modelo'].toString(),
    dados['descricao'].toString(),
    dados['area'].toString(),
    dados['formaPagamento'].toString(),
    double.parse(dados['valor'].toString()),
    int.parse(dados['diasReparo'].toString()),
    dados['dataEntrada'].toString(),
    dados['anoMesEntrada'].toString(),
    dados['dataPagamento'].toString(),
    dados['anoMesPagamento'].toString(),
    int.parse(dados['anoEntrada'].toString()),
  );
}

// Transforma a lista do JSON em uma lista de Atendimento
List<Atendimento> criarListaAtendimentos(List<dynamic> lista) {
  List<Atendimento> atendimentos = [];
  for (dynamic item in lista) {
    atendimentos.add(criarAtendimento(item));
  }
  return atendimentos;
}

// Dados FALSOS, só para o fundo borrado antes do login.
// Assim nenhum nome ou placa real chega no navegador sem login (LGPD).
List<Atendimento> atendimentosDeExemplo() {
  // Nomes repetidos de propósito, para as barras ficarem com tamanhos diferentes
  List<String> modelos = [
    'MODELO A',
    'MODELO A',
    'MODELO A',
    'MODELO B',
    'MODELO B',
    'MODELO C',
    'MODELO D',
    'MODELO E',
  ];
  List<String> areas = [
    'Área 1',
    'Área 1',
    'Área 1',
    'Área 1',
    'Área 2',
    'Área 2',
    'Área 3',
    'Área 4',
    'Área 5',
  ];
  List<String> formas = ['DINHEIRO', 'DINHEIRO', 'DINHEIRO', 'PIX', 'CARTÃO'];
  List<Atendimento> exemplo = [];

  for (int i = 0; i < 80; i++) {
    // Espalha os atendimentos por 20 meses (jan/2025 até ago/2026), de forma desigual
    int mesSequencial = (i * i + 3 * i) % 20;
    int ano = 2025 + mesSequencial ~/ 12; // ~/ = divisão inteira
    String mes = (mesSequencial % 12 + 1).toString().padLeft(2, '0');
    String anoMes = '$ano-$mes';

    exemplo.add(
      Atendimento(
        'EX-$i',
        'Cliente $i',
        i,
        'AAA0000',
        modelos[i % 8],
        'Exemplo',
        areas[i % 9],
        formas[i % 5],
        300.0 + (i * 37) % 1500,
        (i * 5) % 9,
        '$anoMes-10',
        anoMes,
        '$anoMes-15',
        anoMes,
        ano,
      ),
    );
  }
  return exemplo;
}
