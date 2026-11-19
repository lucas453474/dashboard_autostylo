// pecas do dashboard
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'calculos.dart';
import 'cores.dart';
import 'tempos.dart';

const TextStyle estiloTituloCaixa = TextStyle(color: corTexto, fontSize: 11);
const TextStyle estiloSubtitulo = TextStyle(color: corTextoSecundario, fontSize: 10);
const TextStyle estiloEixo = TextStyle(color: corTextoSecundario, fontSize: 9);
const Widget semDados = Center(child: Text('Sem dados', style: estiloSubtitulo));

BoxDecoration decoracaoCaixa() {
  return BoxDecoration(
    color: corCard,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: corBordaCard),
  );
}

BoxDecoration decoracaoFiltro() {
  return BoxDecoration(
    color: corFiltro,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: corGrade),
  );
}

class CaixaGrafico extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget conteudo;

  const CaixaGrafico(this.titulo, this.subtitulo, this.conteudo, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> filhos = [Text(titulo, style: estiloTituloCaixa)];
    if (subtitulo.isNotEmpty) {
      filhos.add(Text(subtitulo, style: estiloSubtitulo));
    }
    filhos.add(const SizedBox(height: 10));
    filhos.add(Expanded(child: conteudo));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: decoracaoCaixa(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: filhos),
    );
  }
}

class CardNumero extends StatelessWidget {
  final String titulo;
  final String valor;

  const CardNumero(this.titulo, this.valor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoracaoCaixa(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(titulo, style: const TextStyle(color: corTextoSecundario, fontSize: 12)),
          const SizedBox(height: 8),
          Text(valor, style: const TextStyle(color: corTexto, fontSize: 26)),
        ],
      ),
    );
  }
}

Widget linhaDaGrade(double posicao, bool vertical) {
  if (vertical) {
    return Align(
      alignment: Alignment(posicao * 2 - 1, 0),
      child: const SizedBox(
        width: 1,
        height: double.infinity,
        child: ColoredBox(color: corGrade),
      ),
    );
  }
  return Align(
    alignment: Alignment(0, 1 - posicao * 2),
    child: const SizedBox(
      width: double.infinity,
      height: 1,
      child: ColoredBox(color: corGrade),
    ),
  );
}

double maiorValor(List<double> valores) {
  double maior = 0;
  for (double valor in valores) {
    if (valor > maior) {
      maior = valor;
    }
  }
  return maior;
}

class BarrasHorizontais extends StatelessWidget {
  final List<String> nomes;
  final List<double> valores;
  final String formato;

  const BarrasHorizontais(this.nomes, this.valores, this.formato, {super.key});

  @override
  Widget build(BuildContext context) {
    double maior = maiorValor(valores);
    if (maior == 0) {
      return semDados;
    }

    List<Widget> grade = [];
    List<Widget> numeros = [];
    for (double marca = 0; marca <= maior; marca += passoDoEixo(maior)) {
      grade.add(linhaDaGrade(marca / maior, true));
      numeros.add(
        Align(
          alignment: Alignment(marca / maior * 2 - 1, 0),
          child: Text(formatarEixo(marca, formato), style: estiloEixo),
        ),
      );
    }

    List<Widget> linhas = [];
    for (int i = 0; i < nomes.length; i++) {
      linhas.add(
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(nomes[i], style: estiloEixo, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: tempoBarras),
                  curve: Curves.easeOut,
                  alignment: Alignment.centerLeft,
                  widthFactor: valores[i] / maior,
                  child: Center(
                    child: Tooltip(
                      message: '${nomes[i]}: ${formatarValor(valores[i], formato)}',
                      child: Container(height: 12, color: corBarraHorizontal),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 128),
                child: Stack(children: grade),
              ),
              Column(children: linhas),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 128),
          child: SizedBox(height: 16, child: Stack(children: numeros)),
        ),
      ],
    );
  }
}

class BarrasVerticais extends StatelessWidget {
  final List<String> rotulos;
  final List<String> dicas;
  final List<double> valores;
  final String formato;

  const BarrasVerticais(this.rotulos, this.dicas, this.valores, this.formato, {super.key});

  @override
  Widget build(BuildContext context) {
    double maior = maiorValor(valores);
    if (maior == 0) {
      return semDados;
    }

    List<Widget> grade = [];
    List<Widget> numeros = [];
    for (double marca = 0; marca <= maior; marca += passoDoEixo(maior)) {
      grade.add(linhaDaGrade(marca / maior, false));
      numeros.add(
        Align(
          alignment: Alignment(1, 1 - marca / maior * 2),
          child: Text(formatarEixo(marca, formato), style: estiloEixo),
        ),
      );
    }

    List<Widget> barras = [];
    List<Widget> textos = [];
    for (int i = 0; i < valores.length; i++) {
      barras.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: tempoBarras),
              curve: Curves.easeOut,
              alignment: Alignment.bottomCenter,
              heightFactor: valores[i] / maior,
              child: Tooltip(
                message: '${dicas[i]}: ${formatarValor(valores[i], formato)}',
                child: Container(color: corBarraVertical),
              ),
            ),
          ),
        ),
      );
      textos.add(
        Expanded(
          child: Center(
            child: Text(
              rotulos[i],
              style: estiloEixo,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      );
    }
    grade.add(Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: barras));

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(width: 56, child: Stack(children: numeros)),
              const SizedBox(width: 6),
              Expanded(child: Stack(children: grade)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 62),
          child: SizedBox(height: 16, child: Row(children: textos)),
        ),
      ],
    );
  }
}

class GraficoLinha extends StatelessWidget {
  final List<String> meses;
  final List<double> valores;

  const GraficoLinha(this.meses, this.valores, {super.key});

  FlLine linhaCinza(double valor) {
    return const FlLine(color: corGrade, strokeWidth: 1);
  }

  Color corDoBalao(LineBarSpot ponto) {
    return corBalao;
  }

  Widget numeroEsquerda(double valor, TitleMeta meta) {
    if (valor % meta.appliedInterval != 0) {
      return const SizedBox();
    }
    return SideTitleWidget(
      meta: meta,
      child: Text(valor.toStringAsFixed(0), style: estiloEixo),
    );
  }

  Widget mesEmbaixo(double valor, TitleMeta meta) {
    int indice = valor.toInt();
    if (indice < 0 || indice >= meses.length || valor != indice) {
      return const SizedBox();
    }
    String rotulo = rotuloDoEixo(meses[indice]);
    if (rotulo.isEmpty) {
      return const SizedBox();
    }
    return SideTitleWidget(
      meta: meta,
      child: Text(rotulo, style: estiloEixo),
    );
  }

  List<LineTooltipItem> textoDoBalao(List<LineBarSpot> pontos) {
    List<LineTooltipItem> itens = [];
    for (LineBarSpot ponto in pontos) {
      itens.add(
        LineTooltipItem(
          '${mesLongo(meses[ponto.x.toInt()])}\n',
          const TextStyle(color: corTexto, fontWeight: FontWeight.bold, fontSize: 12),
          children: [
            TextSpan(
              text: 'Total de Atendimentos   ${ponto.y.toStringAsFixed(0)}',
              style: const TextStyle(color: corTextoSecundario, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      );
    }
    return itens;
  }

  @override
  Widget build(BuildContext context) {
    if (meses.isEmpty) {
      return semDados;
    }

    List<FlSpot> pontos = [];
    for (int i = 0; i < meses.length; i++) {
      pontos.add(FlSpot(i.toDouble(), valores[i]));
    }

    double ultimoX = meses.length - 1;
    if (ultimoX < 1) {
      ultimoX = 1;
    }
    AxisTitles semTitulos = const AxisTitles(sideTitles: SideTitles(showTitles: false));

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: ultimoX,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: linhaCinza),
        titlesData: FlTitlesData(
          topTitles: semTitulos,
          rightTitles: semTitulos,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: numeroEsquerda,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 22,
              getTitlesWidget: mesEmbaixo,
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: corDoBalao,
            getTooltipItems: textoDoBalao,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            maxContentWidth: 220,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: pontos,
            color: corBarraHorizontal,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
      duration: Duration.zero,
    );
  }
}

class TabelaResumo extends StatelessWidget {
  final List<String> meses;
  final List<double> valores;
  final List<double> quantidades;

  const TabelaResumo(this.meses, this.valores, this.quantidades, {super.key});

  Widget linha(String mes, String valor, String total, TextStyle estilo) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: corBordaCard)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(mes, style: estilo)),
          Expanded(
            child: Text(valor, style: estilo, textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(total, style: estilo, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle estilo = const TextStyle(color: corTexto, fontSize: 10);

    List<Widget> linhas = [];
    double somaValor = 0;
    double somaQuantidade = 0;
    for (int i = 0; i < meses.length; i++) {
      List<String> partes = meses[i].split('-');
      String mes = '01/${partes[1]}/${partes[0].substring(2)}';
      linhas.add(linha(mes, formatarReais(valores[i]), quantidades[i].toStringAsFixed(0), estilo));
      somaValor += valores[i];
      somaQuantidade += quantidades[i];
    }

    return Column(
      children: [
        linha('AnoMês', 'Valor dos Serviços', 'Total Atendimentos', estiloSubtitulo),
        Expanded(
          child: SingleChildScrollView(child: Column(children: linhas)),
        ),
        linha(
          'Total',
          formatarReais(somaValor),
          somaQuantidade.toStringAsFixed(0),
          const TextStyle(color: corTexto, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class CaixaFiltro extends StatelessWidget {
  final String titulo;
  final String valorAtual;
  final List<String> opcoes;
  final ValueChanged<String?> aoMudar;

  const CaixaFiltro(this.titulo, this.valorAtual, this.opcoes, this.aoMudar, {super.key});

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<String>> itens = [];
    for (String opcao in opcoes) {
      itens.add(
        DropdownMenuItem<String>(
          value: opcao,
          child: Text(opcao, style: const TextStyle(color: corTexto, fontSize: 12)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(color: corTexto, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          width: 150,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: decoracaoFiltro(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: valorAtual,
              items: itens,
              onChanged: aoMudar,
              isExpanded: true,
              dropdownColor: corFiltro,
              iconEnabledColor: corTexto,
            ),
          ),
        ),
      ],
    );
  }
}

class ItemMenu extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool ativo;
  final VoidCallback aoClicar;

  const ItemMenu(this.icone, this.texto, this.ativo, this.aoClicar, {super.key});

  @override
  Widget build(BuildContext context) {
    Color fundo = Colors.transparent;
    Color barrinha = Colors.transparent;
    if (ativo) {
      fundo = corItemAtivo;
      barrinha = corMenuAtivo;
    }

    return InkWell(
      onTap: aoClicar,
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            Container(width: 4, color: barrinha),
            const SizedBox(width: 12),
            Icon(icone, color: corTexto, size: 18),
            const SizedBox(width: 12),
            Text(
              texto,
              style: const TextStyle(color: corTexto, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
