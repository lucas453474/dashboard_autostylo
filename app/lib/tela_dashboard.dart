import 'package:flutter/material.dart';

import 'atendimento.dart';
import 'calculos.dart';
import 'componentes.dart';
import 'cores.dart';

// Tela do dashboard: menu lateral, cabeçalho com filtros e a página escolhida
class TelaDashboard extends StatefulWidget {
  final List<Atendimento> atendimentos;

  const TelaDashboard(this.atendimentos, {super.key});

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

  // MENU LATERAL: logo, linha separadora, Operação e Financeiro
  Widget menuLateral() {
    return Container(
      width: 200,
      color: corMenu,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Image.asset('assets/logo_autostylo.png', width: 140),
          const SizedBox(height: 16),
          const Divider(color: corGrade, height: 24),
          ItemMenu(Icons.build_outlined, 'Operação', pagina == 'Operação', irParaOperacao),
          ItemMenu(Icons.storage, 'Financeiro', pagina == 'Financeiro', irParaFinanceiro),
        ],
      ),
    );
  }

  // CABEÇALHO: título da página e os filtros
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
                child: CaixaGrafico(
                  'Total de Atendimentos\npor AnoMes',
                  '',
                  GraficoLinha(porMesEntrada.nomes, porMesEntrada.valores),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CardNumero(
                        'Tempo médio de reparo (dias)',
                        formatarNumero(tempoMedioReparo(lista), 2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: CardNumero('Clientes únicos', clientesUnicos(lista).toString()),
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
                child: CaixaGrafico(
                  'Atendimentos por área',
                  '',
                  BarrasHorizontais(porArea.nomes, porArea.valores, 'numero'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CaixaGrafico(
                  'Total de Atendimentos por Modelo',
                  '',
                  BarrasHorizontais(porModelo.nomes, porModelo.valores, 'numero'),
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
              Expanded(child: CardNumero('Valor dos Serviços', formatarMil(valorTotal(lista)))),
              const SizedBox(width: 16),
              Expanded(child: CardNumero('Ticket Médio', formatarReais(ticketMedio(lista)))),
              const SizedBox(width: 16),
              Expanded(child: CardNumero('Atendimentos', lista.length.toString())),
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
                child: CaixaGrafico(
                  'Valor dos serviços por mês',
                  'Valor dos Serviços por AnoMes',
                  BarrasVerticais(rotulosMeses, dicasMeses, valorPorMes.valores, 'mil'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CaixaGrafico(
                  'Valor Por Forma de Pagamento',
                  'Valor dos Serviços por Forma_Pagamento',
                  BarrasVerticais(porForma.nomes, porForma.nomes, porForma.valores, 'mil'),
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
                child: CaixaGrafico(
                  'Valor por área de serviço',
                  '',
                  BarrasHorizontais(porArea.nomes, porArea.valores, 'mil'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CaixaGrafico(
                  'Resumo financeiro mensal',
                  '',
                  TabelaResumo(valorPorMes.nomes, valorPorMes.valores, quantidadePorMes.valores),
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

    Widget conteudo = paginaOperacao(filtrados);
    if (pagina == 'Financeiro') {
      conteudo = paginaFinanceiro(filtrados);
    }

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
                      cabecalho(),
                      const Divider(color: corGrade, height: 28),
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
