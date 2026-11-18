import 'atendimento.dart';

// Todos os cálculos do dashboard ficam aqui, com for e acumulador
// (o mesmo raciocínio do main.dart da aula, só que lendo do MySQL).

List<String> mesesCurtos = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];
List<String> mesesLongos = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

// Resultado de um agrupamento: duas listas "paralelas", como no main.dart da aula
// (nomes[i] combina com valores[i])
class Agrupamento {
  List<String> nomes;
  List<double> valores;

  Agrupamento(this.nomes, this.valores);
}

// FILTROS: escolhe quais atendimentos entram nos cálculos
List<Atendimento> filtrarAtendimentos(List<Atendimento> todos, String periodo, String forma) {
  List<Atendimento> filtrados = [];
  for (Atendimento atendimento in todos) {
    bool periodoOk = periodo == 'Todos' || atendimento.anoEntrada.toString() == periodo;
    bool formaOk = forma == 'Todos' || atendimento.formaPagamento == forma;
    if (periodoOk && formaOk) {
      filtrados.add(atendimento);
    }
  }
  return filtrados;
}

// Soma o valor de todos os atendimentos
double valorTotal(List<Atendimento> lista) {
  double total = 0;
  for (Atendimento atendimento in lista) {
    total += atendimento.valor;
  }
  return total;
}

// Ticket médio = valor total / quantidade de atendimentos
double ticketMedio(List<Atendimento> lista) {
  if (lista.isEmpty) {
    return 0;
  }
  return valorTotal(lista) / lista.length;
}

// Média dos dias de reparo, ignorando os valores negativos (erro de digitação na planilha)
double tempoMedioReparo(List<Atendimento> lista) {
  int soma = 0;
  int quantidade = 0;
  for (Atendimento atendimento in lista) {
    if (atendimento.diasReparo >= 0) {
      soma += atendimento.diasReparo;
      quantidade++;
    }
  }
  if (quantidade == 0) {
    return 0;
  }
  return soma / quantidade;
}

// Conta quantos clientes diferentes existem na lista
int clientesUnicos(List<Atendimento> lista) {
  List<int> vistos = [];
  for (Atendimento atendimento in lista) {
    if (!vistos.contains(atendimento.clienteId)) {
      vistos.add(atendimento.clienteId);
    }
  }
  return vistos.length;
}

// Devolve o campo do atendimento que vai ser usado para agrupar
String chaveDoCampo(Atendimento atendimento, String campo) {
  switch (campo) {
    case 'area':
      return atendimento.area;
    case 'modelo':
      return atendimento.modelo;
    case 'formaPagamento':
      return atendimento.formaPagamento;
    case 'mesEntrada':
      return atendimento.anoMesEntrada;
    case 'mesPagamento':
      return atendimento.anoMesPagamento;
  }
  return '';
}

// AGRUPAR: junta os atendimentos pelo campo escolhido.
// somarValor = true  -> soma o Valor (ex.: valor por forma de pagamento)
// somarValor = false -> conta os atendimentos (ex.: atendimentos por área)
Agrupamento agrupar(List<Atendimento> lista, String campo, bool somarValor) {
  List<String> nomes = [];
  List<double> valores = [];

  for (Atendimento atendimento in lista) {
    String chave = chaveDoCampo(atendimento, campo);
    double quantia = 1;
    if (somarValor) {
      quantia = atendimento.valor;
    }

    // Mesmo raciocínio do "receita por produto" da aula
    int indice = nomes.indexOf(chave);
    if (indice == -1) {
      nomes.add(chave);
      valores.add(quantia);
    } else {
      valores[indice] += quantia;
    }
  }
  return Agrupamento(nomes, valores);
}

// Troca duas posições das listas paralelas
void trocar(Agrupamento grupo, int a, int b) {
  String nomeTemporario = grupo.nomes[a];
  grupo.nomes[a] = grupo.nomes[b];
  grupo.nomes[b] = nomeTemporario;

  double valorTemporario = grupo.valores[a];
  grupo.valores[a] = grupo.valores[b];
  grupo.valores[b] = valorTemporario;
}

// Ordena do maior para o menor valor (empate: ordem alfabética) — bubble sort
void ordenarDoMaior(Agrupamento grupo) {
  for (int i = 0; i < grupo.nomes.length; i++) {
    for (int j = 0; j < grupo.nomes.length - 1 - i; j++) {
      bool menor = grupo.valores[j] < grupo.valores[j + 1];
      bool empate = grupo.valores[j] == grupo.valores[j + 1];
      if (menor || (empate && grupo.nomes[j].compareTo(grupo.nomes[j + 1]) > 0)) {
        trocar(grupo, j, j + 1);
      }
    }
  }
}

// Ordena pelo nome (usado nos meses: '2025-01' vem antes de '2025-02') — bubble sort
void ordenarPorNome(Agrupamento grupo) {
  for (int i = 0; i < grupo.nomes.length; i++) {
    for (int j = 0; j < grupo.nomes.length - 1 - i; j++) {
      if (grupo.nomes[j].compareTo(grupo.nomes[j + 1]) > 0) {
        trocar(grupo, j, j + 1);
      }
    }
  }
}

// Pega só os primeiros itens (ex.: top 5)
Agrupamento primeiros(Agrupamento grupo, int quantidade) {
  List<String> nomes = [];
  List<double> valores = [];
  for (int i = 0; i < grupo.nomes.length && i < quantidade; i++) {
    nomes.add(grupo.nomes[i]);
    valores.add(grupo.valores[i]);
  }
  return Agrupamento(nomes, valores);
}

// Agrupa, ordena do maior e pega o top 5
Agrupamento top5(List<Atendimento> lista, String campo, bool somarValor) {
  Agrupamento grupo = agrupar(lista, campo, somarValor);
  ordenarDoMaior(grupo);
  return primeiros(grupo, 5);
}

// Agrupa por mês e coloca os meses em ordem
Agrupamento porMes(List<Atendimento> lista, String campo, bool somarValor) {
  Agrupamento grupo = agrupar(lista, campo, somarValor);
  ordenarPorNome(grupo);
  return grupo;
}

// ---------- FORMATAÇÃO (padrão brasileiro) ----------

// 130889.6 -> '130.889,60'
String formatarNumero(double numero, int casas) {
  String texto = numero.abs().toStringAsFixed(casas);
  List<String> partes = texto.split('.');
  String inteiro = partes[0];

  // Coloca um ponto a cada 3 dígitos, da direita para a esquerda
  String comPontos = '';
  int contador = 0;
  for (int i = inteiro.length - 1; i >= 0; i--) {
    if (contador == 3) {
      comPontos = '.$comPontos';
      contador = 0;
    }
    comPontos = inteiro[i] + comPontos;
    contador++;
  }

  if (numero < 0) {
    comPontos = '-$comPontos';
  }
  if (casas == 0) {
    return comPontos;
  }
  return '$comPontos,${partes[1]}';
}

// 4169.6 -> 'R$ 4.169,60'
String formatarReais(double valor) {
  return 'R\$ ${formatarNumero(valor, 2)}';
}

// 130889.6 -> 'R$ 130,89 Mil'
String formatarMil(double valor) {
  return 'R\$ ${formatarNumero(valor / 1000, 2)} Mil';
}

// Número do eixo dos gráficos: 'numero' -> '20' | 'mil' -> 'R$ 10 Mil'
String formatarEixo(double valor, String formato) {
  if (formato == 'mil') {
    return 'R\$ ${formatarNumero(valor / 1000, 0)} Mil';
  }
  return formatarNumero(valor, 0);
}

// Valor do balão das barras: 'numero' -> '83' | 'mil' -> 'R$ 4.169,60'
String formatarValor(double valor, String formato) {
  if (formato == 'mil') {
    return formatarReais(valor);
  }
  return formatarNumero(valor, 0);
}

// Número do mês de um texto '2025-01' -> 1
int numeroDoMes(String anoMes) {
  return int.parse(anoMes.split('-')[1]);
}

// '2025-01' -> 'jan 2025' (eixo dos gráficos)
String mesCurto(String anoMes) {
  List<String> partes = anoMes.split('-');
  return '${mesesCurtos[int.parse(partes[1]) - 1]} ${partes[0]}';
}

// '2025-01' -> 'janeiro de 2025' (balão do gráfico de linha)
String mesLongo(String anoMes) {
  List<String> partes = anoMes.split('-');
  return '${mesesLongos[int.parse(partes[1]) - 1]} de ${partes[0]}';
}

// '2025-01' -> '01/01/25' (tabela do resumo, igual ao BI)
String mesTabela(String anoMes) {
  List<String> partes = anoMes.split('-');
  return '01/${partes[1]}/${partes[0].substring(2)}';
}

// Passo "bonito" para as linhas de grade: 1, 2, 5, 10, 20, 50...
double passoDoEixo(double maior) {
  double bruto = maior / 5;
  if (bruto <= 0) {
    return 1;
  }
  double potencia = 1;
  while (bruto >= potencia * 10) {
    potencia = potencia * 10;
  }
  while (bruto < potencia) {
    potencia = potencia / 10;
  }
  double normal = bruto / potencia;
  if (normal <= 1) {
    return potencia;
  }
  if (normal <= 2) {
    return 2 * potencia;
  }
  if (normal <= 5) {
    return 5 * potencia;
  }
  return 10 * potencia;
}
