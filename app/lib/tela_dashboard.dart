// tela do dashboard
import 'package:flutter/material.dart';

import 'atendimento.dart';
import 'calculos.dart';
import 'componentes.dart';
import 'cores.dart';
import 'formulario.dart';
import 'tempos.dart';

class TelaDashboard extends StatefulWidget {
  final List<Atendimento> atendimentos;
  final String token;
  final Future<void> Function() aoCadastrar;
  final GlobalKey chaveLogo;
  final int fase;
  final List<bool> graficosVisiveis;

  const TelaDashboard(
    this.atendimentos,
    this.token,
    this.aoCadastrar,
    this.chaveLogo,
    this.fase,
    this.graficosVisiveis, {
    super.key,
  });

  @override
  State<TelaDashboard> createState() {
    return EstadoDashboard();
  }
}

class EstadoDashboard extends State<TelaDashboard> {
  String pagina = 'Operação';
  String periodo = 'Todos';
  String forma = 'Todos';

  void irParaOperacao() {
    setState(() {
      pagina = 'Operação';
    });
  }

  void irParaFinanceiro() {
    setState(() {
      pagina = 'Financeiro';
    });
  }

  void mudarPeriodo(String? valor) {
    setState(() {
      periodo = valor!;
    });
  }

  void mudarForma(String? valor) {
    setState(() {
      forma = valor!;
    });
  }

  Widget montarFormulario(BuildContext context) {
    return FormularioAtendimento(widget.token);
  }

  Future<void> abrirFormulario(String opcao) async {
    String? mensagem = await showDialog<String>(context: context, builder: montarFormulario);
    if (mensagem == null) {
      return;
    }
    await widget.aoCadastrar();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<PopupMenuEntry<String>> itensDoMenu(BuildContext context) {
    return [
      const PopupMenuItem<String>(
        value: 'atendimento',
        child: Text('Novo atendimento', style: TextStyle(color: corTexto, fontSize: 13)),
      ),
    ];
  }

  double opacidade(bool visivel) {
    if (visivel) {
      return 1;
    }
    return 0;
  }

  Widget aparecer(int indice, Widget filho) {
    bool visivel = widget.graficosVisiveis[indice];
    double escala = 0.95;
    if (visivel) {
      escala = 1;
    }
    return AnimatedOpacity(
      opacity: opacidade(visivel),
      duration: const Duration(milliseconds: tempoGrafico),
      child: AnimatedScale(
        scale: escala,
        duration: const Duration(milliseconds: tempoGrafico),
        curve: Curves.easeOut,
        child: filho,
      ),
    );
  }

  Widget moldura(Widget filho) {
    bool visivel = widget.fase <= 3 || widget.fase >= 5;
    return AnimatedOpacity(
      opacity: opacidade(visivel),
      duration: const Duration(milliseconds: tempoMolduraAparece),
      child: filho,
    );
  }

  Widget duasColunas(int flexA, Widget a, int flexB, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: flexA, child: a),
        const SizedBox(width: 16),
        Expanded(flex: flexB, child: b),
      ],
    );
  }

  Widget menuLateral() {
    bool mostrarLogo = widget.fase <= 1 || widget.fase >= 5;
    return Container(
      width: 200,
      color: corMenu,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Opacity(
            opacity: opacidade(mostrarLogo),
            child: Image.asset('assets/logo_autostylo.png', width: 140, key: widget.chaveLogo),
          ),
          const SizedBox(height: 16),
          moldura(
            Column(
              children: [
                const Divider(color: corGrade, height: 24),
                ItemMenu(Icons.build_outlined, 'Operação', pagina == 'Operação', irParaOperacao),
                ItemMenu(Icons.storage, 'Financeiro', pagina == 'Financeiro', irParaFinanceiro),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget cabecalho() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          pagina,
          style: const TextStyle(color: corTexto, fontSize: 40, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        CaixaFiltro('Período', periodo, ['Todos', '2025', '2026'], mudarPeriodo),
        const SizedBox(width: 16),
        CaixaFiltro('Forma de pagamento', forma, [
          'Todos',
          'DINHEIRO',
          'CARTÃO',
          'PIX',
        ], mudarForma),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          itemBuilder: itensDoMenu,
          onSelected: abrirFormulario,
          color: corFiltro,
          offset: const Offset(0, 34),
          child: Container(
            width: 150,
            height: 30,
            alignment: Alignment.center,
            decoration: decoracaoFiltro(),
            child: const Text('+ Adicionar', style: TextStyle(color: corTexto, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget paginaOperacao(List<Atendimento> lista) {
    Agrupamento porMesEntrada = porMes(lista, 'mesEntrada', false);
    Agrupamento porArea = top5(lista, 'area', false);
    Agrupamento porModelo = top5(lista, 'modelo', false);

    Widget linha = CaixaGrafico(
      'Total de Atendimentos\npor AnoMes',
      '',
      GraficoLinha(porMesEntrada.nomes, porMesEntrada.valores),
    );
    Widget cards = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: aparecer(
            1,
            CardNumero('Tempo médio de reparo (dias)', formatarNumero(tempoMedioReparo(lista), 2)),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: aparecer(2, CardNumero('Clientes únicos', clientesUnicos(lista).toString())),
        ),
      ],
    );
    Widget area = CaixaGrafico(
      'Atendimentos por área',
      '',
      BarrasHorizontais(porArea.nomes, porArea.valores, 'numero'),
    );
    Widget modelo = CaixaGrafico(
      'Total de Atendimentos por Modelo',
      '',
      BarrasHorizontais(porModelo.nomes, porModelo.valores, 'numero'),
    );

    return Column(
      children: [
        Expanded(flex: 11, child: duasColunas(3, aparecer(0, linha), 1, cards)),
        const SizedBox(height: 16),
        Expanded(flex: 9, child: duasColunas(1, aparecer(3, area), 1, aparecer(4, modelo))),
      ],
    );
  }

  Widget paginaFinanceiro(List<Atendimento> lista) {
    Agrupamento valorPorMes = porMes(lista, 'mesPagamento', true);
    Agrupamento quantidadePorMes = porMes(lista, 'mesPagamento', false);
    Agrupamento porForma = top5(lista, 'formaPagamento', true);
    Agrupamento porArea = top5(lista, 'area', true);

    List<String> rotulos = [];
    List<String> dicas = [];
    for (String mes in valorPorMes.nomes) {
      rotulos.add(rotuloDoEixo(mes));
      dicas.add(mesLongo(mes));
    }

    String valorMil = 'R\$ ${formatarNumero(valorTotal(lista) / 1000, 2)} Mil';
    Widget cards = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: aparecer(0, CardNumero('Valor dos Serviços', valorMil))),
        const SizedBox(width: 16),
        Expanded(child: aparecer(1, CardNumero('Ticket Médio', formatarReais(ticketMedio(lista))))),
        const SizedBox(width: 16),
        Expanded(child: aparecer(2, CardNumero('Atendimentos', lista.length.toString()))),
      ],
    );
    Widget mensal = CaixaGrafico(
      'Valor dos serviços por mês',
      'Valor dos Serviços por AnoMes',
      BarrasVerticais(rotulos, dicas, valorPorMes.valores, 'mil'),
    );
    Widget formas = CaixaGrafico(
      'Valor Por Forma de Pagamento',
      'Valor dos Serviços por Forma_Pagamento',
      BarrasVerticais(porForma.nomes, porForma.nomes, porForma.valores, 'mil'),
    );
    Widget area = CaixaGrafico(
      'Valor por área de serviço',
      '',
      BarrasHorizontais(porArea.nomes, porArea.valores, 'mil'),
    );
    Widget resumo = CaixaGrafico(
      'Resumo financeiro mensal',
      '',
      TabelaResumo(valorPorMes.nomes, valorPorMes.valores, quantidadePorMes.valores),
    );

    return Column(
      children: [
        SizedBox(height: 70, child: cards),
        const SizedBox(height: 16),
        Expanded(child: duasColunas(3, aparecer(3, mensal), 2, aparecer(4, formas))),
        const SizedBox(height: 16),
        Expanded(child: duasColunas(1, aparecer(5, area), 1, aparecer(6, resumo))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Atendimento> filtrados = filtrarAtendimentos(widget.atendimentos, periodo, forma);

    Widget paginaEscolhida = paginaOperacao(filtrados);
    if (pagina == 'Financeiro') {
      paginaEscolhida = paginaFinanceiro(filtrados);
    }

    return SizedBox.expand(
      child: FittedBox(
        child: SizedBox(
          width: 1280,
          height: 720,
          child: Row(
            children: [
              menuLateral(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    children: [
                      moldura(cabecalho()),
                      moldura(const Divider(color: corGrade, height: 28)),
                      // chave por pagina para as barras nao deslizarem ao trocar
                      Expanded(
                        child: KeyedSubtree(key: ValueKey<String>(pagina), child: paginaEscolhida),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
