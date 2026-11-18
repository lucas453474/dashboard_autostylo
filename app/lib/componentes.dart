import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'calculos.dart';
import 'cores.dart';
import 'tempos.dart';

// Estilos de texto usados em vários lugares
const TextStyle estiloTituloCaixa = TextStyle(color: corTexto, fontSize: 11);
const TextStyle estiloSubtitulo = TextStyle(color: corTextoSecundario, fontSize: 10);
const TextStyle estiloEixo = TextStyle(color: corTextoSecundario, fontSize: 9);

// Decoração das caixas (fundo, borda sutil e cantos arredondados)
BoxDecoration decoracaoCaixa() {
  return BoxDecoration(
    color: corCard,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: corBordaCard),
  );
}

// Caixa com título onde ficam os gráficos
class CaixaGrafico extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget conteudo;

  const CaixaGrafico(this.titulo, this.subtitulo, this.conteudo, {super.key});

  @override
  Widget build(BuildContext context) {
    // Monta a lista de filhos: título, subtítulo (se tiver) e o gráfico
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

// Card com um número grande (ex.: Clientes únicos 131)
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

// Linha da grade colocada numa posição de 0.0 (início) a 1.0 (fim)
// Alignment vai de -1 (esquerda/baixo) até 1 (direita/cima)
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

// Maior número da lista (o tamanho de cada barra é valor / maiorValor)
double maiorValor(List<double> valores) {
  double maior = 0;
  for (double valor in valores) {
    if (valor > maior) {
      maior = valor;
    }
  }
  return maior;
}

// BARRAS HORIZONTAIS feitas à mão: um Container por barra, dentro de um for
class BarrasHorizontais extends StatelessWidget {
  final List<String> nomes;
  final List<double> valores;
  final String formato; // 'numero' ou 'mil'

  const BarrasHorizontais(this.nomes, this.valores, this.formato, {super.key});

  // Desenha as barras. O LayoutBuilder entrega a largura disponível (limites.maxWidth)
  // e o AnimatedContainer faz a barra deslizar até o novo tamanho quando o filtro muda.
  Widget desenharBarras(BuildContext context, BoxConstraints limites) {
    double maior = maiorValor(valores);
    List<Widget> colunaBarras = [];
    for (int i = 0; i < nomes.length; i++) {
      colunaBarras.add(
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: '${nomes[i]}: ${formatarValor(valores[i], formato)}',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: tempoBarras),
                curve: curvaEntrada,
                width: limites.maxWidth * valores[i] / maior,
                height: 12,
                color: corBarraHorizontal,
              ),
            ),
          ),
        ),
      );
    }
    return Column(children: colunaBarras);
  }

  @override
  Widget build(BuildContext context) {
    double maior = maiorValor(valores);
    if (maior == 0) {
      return const Center(child: Text('Sem dados', style: estiloSubtitulo));
    }
    double passo = passoDoEixo(maior);

    // Nomes à esquerda (as barras ficam à direita, em desenharBarras)
    List<Widget> colunaNomes = [];
    for (int i = 0; i < nomes.length; i++) {
      colunaNomes.add(
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(nomes[i], style: estiloEixo, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    }
    colunaNomes.add(const SizedBox(height: 16));

    // Linhas da grade e números do eixo de baixo
    List<Widget> grade = [];
    List<Widget> numerosEixo = [];
    for (double marca = 0; marca <= maior; marca += passo) {
      grade.add(linhaDaGrade(marca / maior, true));
      numerosEixo.add(
        Align(
          alignment: Alignment(marca / maior * 2 - 1, 0),
          child: Text(formatarEixo(marca, formato), style: estiloEixo),
        ),
      );
    }
    grade.add(LayoutBuilder(builder: desenharBarras));

    return Row(
      children: [
        SizedBox(width: 120, child: Column(children: colunaNomes)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(child: Stack(children: grade)),
              SizedBox(height: 16, child: Stack(children: numerosEixo)),
            ],
          ),
        ),
      ],
    );
  }
}

// BARRAS VERTICAIS feitas à mão: um Container por barra, dentro de um for
class BarrasVerticais extends StatelessWidget {
  final List<String> rotulos; // texto embaixo de cada barra ('' = sem texto)
  final List<String> dicas; // texto do balão ao passar o mouse
  final List<double> valores;
  final String formato; // 'numero' ou 'mil'

  const BarrasVerticais(this.rotulos, this.dicas, this.valores, this.formato, {super.key});

  // Desenha as barras. O LayoutBuilder entrega a altura disponível (limites.maxHeight)
  // e o AnimatedContainer faz a barra subir/descer até o novo tamanho quando o filtro muda.
  Widget desenharBarras(BuildContext context, BoxConstraints limites) {
    double maior = maiorValor(valores);
    List<Widget> barras = [];
    for (int i = 0; i < valores.length; i++) {
      barras.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Tooltip(
                message: '${dicas[i]}: ${formatarValor(valores[i], formato)}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: tempoBarras),
                  curve: curvaEntrada,
                  width: double.infinity,
                  height: limites.maxHeight * valores[i] / maior,
                  color: corBarraVertical,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: barras);
  }

  @override
  Widget build(BuildContext context) {
    double maior = maiorValor(valores);
    if (maior == 0) {
      return const Center(child: Text('Sem dados', style: estiloSubtitulo));
    }
    double passo = passoDoEixo(maior);

    // Linhas da grade e números do eixo da esquerda
    List<Widget> grade = [];
    List<Widget> numerosEixo = [];
    for (double marca = 0; marca <= maior; marca += passo) {
      grade.add(linhaDaGrade(marca / maior, false));
      numerosEixo.add(
        Align(
          alignment: Alignment(1, 1 - marca / maior * 2),
          child: Text(formatarEixo(marca, formato), style: estiloEixo),
        ),
      );
    }

    // Um rótulo embaixo de cada barra (as barras ficam em desenharBarras)
    List<Widget> textosEmbaixo = [];
    for (int i = 0; i < valores.length; i++) {
      textosEmbaixo.add(
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
    grade.add(LayoutBuilder(builder: desenharBarras));

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(width: 56, child: Stack(children: numerosEixo)),
              const SizedBox(width: 6),
              Expanded(child: Stack(children: grade)),
            ],
          ),
        ),
        SizedBox(
          height: 16,
          child: Row(
            children: [
              const SizedBox(width: 62),
              Expanded(child: Row(children: textosEmbaixo)),
            ],
          ),
        ),
      ],
    );
  }
}

// GRÁFICO DE LINHA (o único que usa pacote: fl_chart)
class GraficoLinha extends StatelessWidget {
  final List<String> meses; // '2025-01', '2025-02', ...
  final List<double> valores;

  const GraficoLinha(this.meses, this.valores, {super.key});

  // Linha cinza da grade
  FlLine linhaCinza(double valor) {
    return const FlLine(color: corGrade, strokeWidth: 1);
  }

  // Números do eixo da esquerda
  Widget numeroEsquerda(double valor, TitleMeta meta) {
    // Esconde o número da ponta que não cai no intervalo (ex.: 3 quando o passo é 2)
    if (valor % meta.appliedInterval != 0) {
      return const SizedBox();
    }
    return SideTitleWidget(
      meta: meta,
      child: Text(valor.toStringAsFixed(0), style: estiloEixo),
    );
  }

  // Meses do eixo de baixo (só jan, abr, jul e out, igual ao BI)
  Widget mesEmbaixo(double valor, TitleMeta meta) {
    int indice = valor.toInt();
    if (indice < 0 || indice >= meses.length || valor != indice) {
      return const SizedBox();
    }
    int mes = numeroDoMes(meses[indice]);
    if (mes != 1 && mes != 4 && mes != 7 && mes != 10) {
      return const SizedBox();
    }
    return SideTitleWidget(
      meta: meta,
      child: Text(mesCurto(meses[indice]), style: estiloEixo),
    );
  }

  // Cor de fundo do balão
  Color corDoBalao(LineBarSpot ponto) {
    return const Color(0xFF2B2D30);
  }

  // Texto do balão: "janeiro de 2025 — Total de Atendimentos 7"
  List<LineTooltipItem> textoDoBalao(List<LineBarSpot> pontos) {
    List<LineTooltipItem> itens = [];
    for (LineBarSpot ponto in pontos) {
      String mes = mesLongo(meses[ponto.x.toInt()]);
      itens.add(
        LineTooltipItem(
          '$mes\n',
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
      return const Center(child: Text('Sem dados', style: estiloSubtitulo));
    }

    // Um ponto (x = posição do mês, y = total) para cada mês
    List<FlSpot> pontos = [];
    for (int i = 0; i < meses.length; i++) {
      pontos.add(FlSpot(i.toDouble(), valores[i]));
    }

    AxisTitles semTitulos = const AxisTitles(sideTitles: SideTitles(showTitles: false));

    // O eixo X vai do primeiro ao último mês (no mínimo 1, para não ficar com largura zero)
    double ultimoX = meses.length - 1;
    if (ultimoX < 1) {
      ultimoX = 1;
    }

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
      // A linha desliza até os novos valores quando o filtro muda (igual às barras)
      duration: const Duration(milliseconds: tempoBarras),
      curve: curvaEntrada,
    );
  }
}

// TABELA "Resumo financeiro mensal" (com rolagem e linha de Total)
class TabelaResumo extends StatelessWidget {
  final List<String> meses;
  final List<double> valores;
  final List<double> quantidades;

  const TabelaResumo(this.meses, this.valores, this.quantidades, {super.key});

  // Uma linha da tabela com 3 colunas
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
    TextStyle estiloCabecalho = const TextStyle(color: corTextoSecundario, fontSize: 10);

    // Uma linha por mês, somando o total no final
    List<Widget> linhas = [];
    double somaValor = 0;
    double somaQuantidade = 0;
    for (int i = 0; i < meses.length; i++) {
      linhas.add(
        linha(
          mesTabela(meses[i]),
          formatarReais(valores[i]),
          quantidades[i].toStringAsFixed(0),
          estilo,
        ),
      );
      somaValor += valores[i];
      somaQuantidade += quantidades[i];
    }

    return Column(
      children: [
        linha('AnoMês', 'Valor dos Serviços', 'Total Atendimentos', estiloCabecalho),
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

// FILTRO (dropdown) com o título em cima — igual aos filtros do BI
class CaixaFiltro extends StatelessWidget {
  final String titulo;
  final String valorAtual;
  final List<String> opcoes;
  final ValueChanged<String?> aoMudar; // função chamada quando escolhe uma opção

  const CaixaFiltro(this.titulo, this.valorAtual, this.opcoes, this.aoMudar, {super.key});

  @override
  Widget build(BuildContext context) {
    // Um item no dropdown para cada opção
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

// Decoração dos filtros (o botão "+ Adicionar" usa a mesma)
BoxDecoration decoracaoFiltro() {
  return BoxDecoration(
    color: corFiltro,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: corGrade),
  );
}

// ITEM DO MENU LATERAL (Operação / Financeiro)
class ItemMenu extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool ativo;
  final VoidCallback aoClicar; // função chamada no clique

  const ItemMenu(this.icone, this.texto, this.ativo, this.aoClicar, {super.key});

  @override
  Widget build(BuildContext context) {
    // O item ativo tem fundo mais claro e uma barrinha azul na esquerda
    Color fundo = Colors.transparent;
    Color barrinha = Colors.transparent;
    if (ativo) {
      fundo = corItemAtivo;
      barrinha = corMenuAtivo;
    }

    // AnimatedContainer: o fundo e a barrinha mudam rápido, mas sem "piscar"
    return InkWell(
      onTap: aoClicar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: tempoClique),
        curve: curvaEntrada,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: tempoClique),
              curve: curvaEntrada,
              width: 4,
              color: barrinha,
            ),
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
