// conta os numeros dos graficos
import 'atendimento.dart';

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

class Agrupamento {
  List<String> nomes;
  List<double> valores;

  Agrupamento(this.nomes, this.valores);
}

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

double valorTotal(List<Atendimento> lista) {
  double total = 0;
  for (Atendimento atendimento in lista) {
    total += atendimento.valor;
  }
  return total;
}

double ticketMedio(List<Atendimento> lista) {
  if (lista.isEmpty) {
    return 0;
  }
  return valorTotal(lista) / lista.length;
}

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

int clientesUnicos(List<Atendimento> lista) {
  List<int> vistos = [];
  for (Atendimento atendimento in lista) {
    if (!vistos.contains(atendimento.clienteId)) {
      vistos.add(atendimento.clienteId);
    }
  }
  return vistos.length;
}

Agrupamento agrupar(List<Atendimento> lista, String campo, bool somarValor) {
  List<String> nomes = [];
  List<double> valores = [];

  for (Atendimento atendimento in lista) {
    String chave = atendimento.area;
    if (campo == 'modelo') {
      chave = atendimento.modelo;
    } else if (campo == 'formaPagamento') {
      chave = atendimento.formaPagamento;
    } else if (campo == 'mesEntrada') {
      chave = atendimento.anoMesEntrada;
    } else if (campo == 'mesPagamento') {
      chave = atendimento.anoMesPagamento;
    }

    double quantia = 1;
    if (somarValor) {
      quantia = atendimento.valor;
    }

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

void ordenar(Agrupamento grupo, bool porNome) {
  for (int i = 0; i < grupo.nomes.length; i++) {
    for (int j = 0; j < grupo.nomes.length - 1 - i; j++) {
      bool nomeDepois = grupo.nomes[j].compareTo(grupo.nomes[j + 1]) > 0;
      bool trocar = nomeDepois;
      if (!porNome) {
        bool menor = grupo.valores[j] < grupo.valores[j + 1];
        bool empate = grupo.valores[j] == grupo.valores[j + 1];
        trocar = menor || (empate && nomeDepois);
      }

      if (trocar) {
        String nome = grupo.nomes[j];
        grupo.nomes[j] = grupo.nomes[j + 1];
        grupo.nomes[j + 1] = nome;
        double valor = grupo.valores[j];
        grupo.valores[j] = grupo.valores[j + 1];
        grupo.valores[j + 1] = valor;
      }
    }
  }
}

Agrupamento top5(List<Atendimento> lista, String campo, bool somarValor) {
  Agrupamento grupo = agrupar(lista, campo, somarValor);
  ordenar(grupo, false);

  List<String> nomes = [];
  List<double> valores = [];
  for (int i = 0; i < grupo.nomes.length && i < 5; i++) {
    nomes.add(grupo.nomes[i]);
    valores.add(grupo.valores[i]);
  }
  return Agrupamento(nomes, valores);
}

Agrupamento porMes(List<Atendimento> lista, String campo, bool somarValor) {
  Agrupamento grupo = agrupar(lista, campo, somarValor);
  ordenar(grupo, true);
  return grupo;
}

String formatarNumero(double numero, int casas) {
  List<String> partes = numero.toStringAsFixed(casas).split('.');
  String inteiro = partes[0];

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

  if (casas == 0) {
    return comPontos;
  }
  return '$comPontos,${partes[1]}';
}

String formatarReais(double valor) {
  return 'R\$ ${formatarNumero(valor, 2)}';
}

String formatarEixo(double valor, String formato) {
  if (formato == 'mil') {
    return 'R\$ ${formatarNumero(valor / 1000, 0)} Mil';
  }
  return formatarNumero(valor, 0);
}

String formatarValor(double valor, String formato) {
  if (formato == 'mil') {
    return formatarReais(valor);
  }
  return formatarNumero(valor, 0);
}

String rotuloDoEixo(String anoMes) {
  List<String> partes = anoMes.split('-');
  int mes = int.parse(partes[1]);
  if (mes != 1 && mes != 4 && mes != 7 && mes != 10) {
    return '';
  }
  return '${mesesCurtos[mes - 1]} ${partes[0]}';
}

String mesLongo(String anoMes) {
  List<String> partes = anoMes.split('-');
  return '${mesesLongos[int.parse(partes[1]) - 1]} de ${partes[0]}';
}

double passoDoEixo(double maior) {
  double bruto = maior / 5;
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
