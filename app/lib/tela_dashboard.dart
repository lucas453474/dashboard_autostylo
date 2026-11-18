import 'package:flutter/material.dart';

import 'atendimento.dart';
import 'calculos.dart';
import 'componentes.dart';
import 'cores.dart';
import 'formulario.dart';
import 'tempos.dart';

// Tela do dashboard: menu lateral, cabeçalho com filtros e a página escolhida
class TelaDashboard extends StatefulWidget {
  final List<Atendimento> atendimentos;
  final String token;
  // Função da tela principal que busca os dados de novo depois de um cadastro
  final Future<void> Function() aoCadastrar;

  // Controles da animação de entrada (quem decide é a tela principal, em main.dart)
  final GlobalKey chaveLogo; // "etiqueta" para descobrir onde a logo do menu está na tela
  final bool mostrarLogo;
  final bool mostrarMoldura; // menu (itens) + cabeçalho
  final List<bool> graficosVisiveis; // um bool para cada card/gráfico, na ordem de leitura

  const TelaDashboard(
    this.atendimentos,
    this.token,
    this.aoCadastrar,
    this.chaveLogo,
    this.mostrarLogo,
    this.mostrarMoldura,
    this.graficosVisiveis, {
    super.key,
  });

  @override
  State<TelaDashboard> createState() {
    return EstadoDashboard();
  }
}

class EstadoDashboard extends State<TelaDashboard> {
  // O que está escolhido agora (os filtros começam em "Todos")
  String pagina = 'Operação';
  String periodo = 'Todos';
  String forma = 'Todos';

  // setState avisa o Flutter que algo mudou e a tela precisa ser redesenhada
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
    if (valor == null) {
      return;
    }
    setState(() {
      periodo = valor;
    });
  }

  void mudarForma(String? valor) {
    if (valor == null) {
      return;
    }
    setState(() {
      forma = valor;
    });
  }

  // Monta a janela do formulário (o showDialog pede uma função que devolve o widget)
  Widget montarFormulario(BuildContext context) {
    return FormularioAtendimento(widget.token);
  }

  // Abre o formulário; se salvou, recarrega os dados e mostra a mensagem da API
  Future<void> abrirFormulario() async {
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

  // Itens da listinha do botão "+ Adicionar"
  List<PopupMenuEntry<String>> itensDoMenu(BuildContext context) {
    return [
      const PopupMenuItem<String>(
        value: 'atendimento',
        child: Text('Novo atendimento', style: TextStyle(color: corTexto, fontSize: 13)),
      ),
    ];
  }

  // Clique num item da listinha
  void escolheuNoMenu(String opcao) {
    if (opcao == 'atendimento') {
      abrirFormulario();
    }
  }

  // Botão "+ Adicionar", com o mesmo estilo dos filtros
  Widget botaoAdicionar() {
    return PopupMenuButton<String>(
      itemBuilder: itensDoMenu,
      onSelected: escolheuNoMenu,
      color: corFiltro,
      offset: const Offset(0, 34),
      child: Container(
        width: 150,
        height: 30,
        alignment: Alignment.center,
        decoration: decoracaoFiltro(),
        child: const Text('+ Adicionar', style: TextStyle(color: corTexto, fontSize: 12)),
      ),
    );
  }

  // Opacidade 1 (aparece) ou 0 (escondido)
  double opacidade(bool visivel) {
    if (visivel) {
      return 1;
    }
    return 0;
  }

  // Card/gráfico que "aparece": fade + escala 0.95 -> 1.0
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

  // Menu e cabeçalho aparecem juntos (fade)
  Widget moldura(Widget filho) {
    return AnimatedOpacity(
      opacity: opacidade(widget.mostrarMoldura),
      duration: const Duration(milliseconds: tempoMolduraAparece),
      child: filho,
    );
  }

  // MENU LATERAL: logo, linha separadora, Operação e Financeiro
  Widget menuLateral() {
    return Container(
      width: 200,
      color: corMenu,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // A logo some e aparece sem animação: quem anima é a cópia que "voa" (main.dart)
          Opacity(
            opacity: opacidade(widget.mostrarLogo),
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

  // CABEÇALHO: título da página, os filtros e o botão "+ Adicionar"
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
        botaoAdicionar(),
      ],
    );
  }

  // PÁGINA OPERAÇÃO
  Widget paginaOperacao(List<Atendimento> lista) {
    Agrupamento porMesEntrada = porMes(lista, 'mesEntrada', false);
    Agrupamento porArea = top5(lista, 'area', false);
    Agrupamento porModelo = top5(lista, 'modelo', false);

    return Column(
      children: [
        Expanded(
          flex: 11,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: aparecer(
                  0,
                  CaixaGrafico(
                    'Total de Atendimentos\npor AnoMes',
                    '',
                    GraficoLinha(porMesEntrada.nomes, porMesEntrada.valores),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: aparecer(
                        1,
                        CardNumero(
                          'Tempo médio de reparo (dias)',
                          formatarNumero(tempoMedioReparo(lista), 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: aparecer(
                        2,
                        CardNumero('Clientes únicos', clientesUnicos(lista).toString()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 9,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: aparecer(
                  3,
                  CaixaGrafico(
                    'Atendimentos por área',
                    '',
                    BarrasHorizontais(porArea.nomes, porArea.valores, 'numero'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: aparecer(
                  4,
                  CaixaGrafico(
                    'Total de Atendimentos por Modelo',
                    '',
                    BarrasHorizontais(porModelo.nomes, porModelo.valores, 'numero'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // PÁGINA FINANCEIRO
  Widget paginaFinanceiro(List<Atendimento> lista) {
    // Os meses do Financeiro são pela data de PAGAMENTO
    Agrupamento valorPorMes = porMes(lista, 'mesPagamento', true);
    Agrupamento quantidadePorMes = porMes(lista, 'mesPagamento', false);
    Agrupamento porForma = agrupar(lista, 'formaPagamento', true);
    ordenarDoMaior(porForma);
    Agrupamento porArea = top5(lista, 'area', true);

    // Rótulos do eixo dos meses: só jan, abr, jul e out (igual ao BI)
    List<String> rotulosMeses = [];
    List<String> dicasMeses = [];
    for (String mes in valorPorMes.nomes) {
      int numero = numeroDoMes(mes);
      if (numero == 1 || numero == 4 || numero == 7 || numero == 10) {
        rotulosMeses.add(mesCurto(mes));
      } else {
        rotulosMeses.add('');
      }
      dicasMeses.add(mesLongo(mes));
    }

    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: aparecer(
                  0,
                  CardNumero('Valor dos Serviços', formatarMil(valorTotal(lista))),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: aparecer(1, CardNumero('Ticket Médio', formatarReais(ticketMedio(lista)))),
              ),
              const SizedBox(width: 16),
              Expanded(child: aparecer(2, CardNumero('Atendimentos', lista.length.toString()))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: aparecer(
                  3,
                  CaixaGrafico(
                    'Valor dos serviços por mês',
                    'Valor dos Serviços por AnoMes',
                    BarrasVerticais(rotulosMeses, dicasMeses, valorPorMes.valores, 'mil'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: aparecer(
                  4,
                  CaixaGrafico(
                    'Valor Por Forma de Pagamento',
                    'Valor dos Serviços por Forma_Pagamento',
                    BarrasVerticais(porForma.nomes, porForma.nomes, porForma.valores, 'mil'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: aparecer(
                  5,
                  CaixaGrafico(
                    'Valor por área de serviço',
                    '',
                    BarrasHorizontais(porArea.nomes, porArea.valores, 'mil'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: aparecer(
                  6,
                  CaixaGrafico(
                    'Resumo financeiro mensal',
                    '',
                    TabelaResumo(valorPorMes.nomes, valorPorMes.valores, quantidadePorMes.valores),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // O filtro só escolhe quais atendimentos entram nos cálculos
    List<Atendimento> filtrados = filtrarAtendimentos(widget.atendimentos, periodo, forma);

    Widget paginaEscolhida = paginaOperacao(filtrados);
    if (pagina == 'Financeiro') {
      paginaEscolhida = paginaFinanceiro(filtrados);
    }
    // A chave com o nome da página faz o Flutter montar a página do zero ao trocar,
    // assim as barras não "deslizam" da página anterior (só animam ao mudar o filtro)
    Widget conteudo = KeyedSubtree(key: ValueKey<String>(pagina), child: paginaEscolhida);

    // Desenhamos tudo num "quadro" de 1280x720 (igual à página do BI)
    // e o FittedBox aumenta ou diminui o quadro para caber na janela
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
                      Expanded(child: conteudo),
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
