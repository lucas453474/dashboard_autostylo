// classe atendimento e dados de exemplo
class Atendimento {
  int clienteId;
  String modelo;
  String area;
  String formaPagamento;
  double valor;
  int diasReparo;
  String anoMesEntrada;
  String anoMesPagamento;
  int anoEntrada;

  Atendimento(
    this.clienteId,
    this.modelo,
    this.area,
    this.formaPagamento,
    this.valor,
    this.diasReparo,
    this.anoMesEntrada,
    this.anoMesPagamento,
    this.anoEntrada,
  );
}

Atendimento criarAtendimento(Map<String, dynamic> dados) {
  return Atendimento(
    int.parse(dados['clienteId'].toString()),
    dados['modelo'].toString(),
    dados['area'].toString(),
    dados['formaPagamento'].toString(),
    double.parse(dados['valor'].toString()),
    int.parse(dados['diasReparo'].toString()),
    dados['anoMesEntrada'].toString(),
    dados['anoMesPagamento'].toString(),
    int.parse(dados['anoEntrada'].toString()),
  );
}

List<Atendimento> criarListaAtendimentos(List<dynamic> lista) {
  List<Atendimento> atendimentos = [];
  for (dynamic item in lista) {
    atendimentos.add(criarAtendimento(item));
  }
  return atendimentos;
}

List<Atendimento> atendimentosDeExemplo() {
  List<String> modelos = ['A', 'A', 'A', 'B', 'B', 'C', 'D', 'E'];
  List<String> formas = ['DINHEIRO', 'DINHEIRO', 'DINHEIRO', 'PIX', 'CARTÃO'];
  List<int> areas = [1, 1, 1, 1, 2, 2, 3, 4, 5];
  List<Atendimento> exemplo = [];

  for (int i = 0; i < 80; i++) {
    int mesSequencial = (i * i + 3 * i) % 20;
    int ano = 2025 + mesSequencial ~/ 12;
    String mes = (mesSequencial % 12 + 1).toString().padLeft(2, '0');

    exemplo.add(
      Atendimento(
        i,
        'MODELO ${modelos[i % 8]}',
        'Área ${areas[i % 9]}',
        formas[i % 5],
        300.0 + (i * 37) % 1500,
        (i * 5) % 9,
        '$ano-$mes',
        '$ano-$mes',
        ano,
      ),
    );
  }
  return exemplo;
}
