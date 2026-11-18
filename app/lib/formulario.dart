import 'package:flutter/material.dart';

import 'api.dart';
import 'componentes.dart';
import 'cores.dart';

// As 11 áreas que já existem em Dim_Servico.Area_Principal
List<String> areasServico = [
  'Capô',
  'Lateral',
  'Múltiplas áreas',
  'Outros / não classificado',
  'Para-choque',
  'Para-lama',
  'Portas',
  'Retoque',
  'Rodas',
  'Tampa traseira',
  'Teto',
];

// As formas de pagamento de Dim_Pagamento
List<String> formasPagamento = ['DINHEIRO', 'CARTÃO', 'PIX'];

// Verifica se o campo foi preenchido: devolve a mensagem de erro, ou '' se estiver ok
String validaCampoVazio(String valor, String nomeCampo) {
  if (valor.trim().isEmpty) {
    return 'Preencha o campo "$nomeCampo".';
  }
  return '';
}

// '2026-11-18' -> '18/11/2026' (para mostrar na tela)
String dataNaTela(String data) {
  if (data.isEmpty) {
    return 'Escolher data';
  }
  List<String> partes = data.split('-');
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}

// DateTime -> '2026-11-18' (formato que a API espera)
String dataParaApi(DateTime data) {
  String mes = data.month.toString().padLeft(2, '0');
  String dia = data.day.toString().padLeft(2, '0');
  return '${data.year}-$mes-$dia';
}

// Formulário "Novo atendimento" (abre numa janela por cima do dashboard)
class FormularioAtendimento extends StatefulWidget {
  final String token;

  const FormularioAtendimento(this.token, {super.key});

  @override
  State<FormularioAtendimento> createState() {
    return EstadoFormulario();
  }
}

class EstadoFormulario extends State<FormularioAtendimento> {
  TextEditingController campoCliente = TextEditingController();
  TextEditingController campoPlaca = TextEditingController();
  TextEditingController campoModelo = TextEditingController();
  TextEditingController campoCor = TextEditingController();
  TextEditingController campoDescricao = TextEditingController();
  TextEditingController campoValor = TextEditingController();

  // Listas e datas escolhidas ('' = ainda não escolheu)
  String area = '';
  String forma = '';
  String dataEntrada = '';
  String dataSaida = '';
  String dataPagamento = '';

  String erro = '';
  bool salvando = false;

  void mudarArea(String? valor) {
    if (valor == null) {
      return;
    }
    setState(() {
      area = valor;
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

  // Abre o calendário e devolve a data escolhida ('' se cancelar)
  Future<String> escolherData() async {
    DateTime? escolhida = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      helpText: 'Escolha a data',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (escolhida == null) {
      return '';
    }
    return dataParaApi(escolhida);
  }

  Future<void> escolherEntrada() async {
    String data = await escolherData();
    if (data.isEmpty) {
      return;
    }
    setState(() {
      dataEntrada = data;
    });
  }

  Future<void> escolherSaida() async {
    String data = await escolherData();
    if (data.isEmpty) {
      return;
    }
    setState(() {
      dataSaida = data;
    });
  }

  Future<void> escolherPagamento() async {
    String data = await escolherData();
    if (data.isEmpty) {
      return;
    }
    setState(() {
      dataPagamento = data;
    });
  }

  void mostrarErro(String mensagem) {
    setState(() {
      erro = mensagem;
      salvando = false;
    });
  }

  // Clique em Salvar: valida, manda para a API (POST /cadastrar) e fecha a janela
  Future<void> salvar() async {
    // Captura os dados do formulário
    String cliente = campoCliente.text.trim();
    String placa = campoPlaca.text.trim();
    String modelo = campoModelo.text.trim();
    String cor = campoCor.text.trim();
    String descricao = campoDescricao.text.trim();
    String textoValor = campoValor.text.trim();

    // Verifica se algum campo ficou vazio (um por um, com o nome do campo)
    List<String> valores = [
      cliente,
      placa,
      modelo,
      cor,
      descricao,
      area,
      textoValor,
      forma,
      dataEntrada,
      dataSaida,
      dataPagamento,
    ];
    List<String> nomes = [
      'Cliente',
      'Placa',
      'Modelo',
      'Cor',
      'O que foi feito',
      'Área',
      'Valor',
      'Forma de pagamento',
      'Data de entrada',
      'Data de saída',
      'Data de pagamento',
    ];
    for (int i = 0; i < valores.length; i++) {
      String mensagem = validaCampoVazio(valores[i], nomes[i]);
      if (mensagem.isNotEmpty) {
        mostrarErro(mensagem);
        return;
      }
    }

    // Aceita valor com vírgula: '1.200,50' -> '1200.50'
    if (textoValor.contains(',')) {
      textoValor = textoValor.replaceAll('.', '').replaceAll(',', '.');
    }
    double? valor = double.tryParse(textoValor);
    if (valor == null || valor <= 0) {
      mostrarErro('Digite um valor válido (ex.: 850,00).');
      return;
    }

    setState(() {
      salvando = true;
      erro = '';
    });

    // Monta o JSON e manda para a API
    Map<String, dynamic> dados = {
      'cliente': cliente,
      'placa': placa,
      'modelo': modelo,
      'cor': cor,
      'descricao': descricao,
      'area': area,
      'valor': valor.toStringAsFixed(2),
      'formaPagamento': forma,
      'dataEntrada': dataEntrada,
      'dataSaida': dataSaida,
      'dataPagamento': dataPagamento,
    };
    Map<String, dynamic> resposta = await cadastrarAtendimento(widget.token, dados);

    // A API recusou (ex.: saída antes da entrada): mostra a mensagem dela
    if (resposta['STATUS'] != 1) {
      mostrarErro(resposta['MSG'].toString());
      return;
    }

    // Deu certo: fecha a janela e devolve a mensagem para o dashboard
    if (!mounted) {
      return;
    }
    Navigator.pop(context, resposta['MSG'].toString());
  }

  void cancelar() {
    Navigator.pop(context);
  }

  // Campo de texto com rótulo
  Widget campoTexto(String rotulo, TextEditingController controle) {
    return TextField(
      controller: controle,
      style: const TextStyle(color: corTexto, fontSize: 13),
      decoration: InputDecoration(
        labelText: rotulo,
        labelStyle: const TextStyle(color: corTextoSecundario, fontSize: 13),
        filled: true,
        fillColor: corFiltro,
        isDense: true,
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: corGrade)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: corMenuAtivo)),
      ),
    );
  }

  // Lista de opções (dropdown) com rótulo
  Widget campoLista(
    String rotulo,
    String valor,
    List<String> opcoes,
    ValueChanged<String?> aoMudar,
  ) {
    List<DropdownMenuItem<String>> itens = [];
    for (String opcao in opcoes) {
      itens.add(DropdownMenuItem<String>(value: opcao, child: Text(opcao)));
    }

    // null = nada escolhido ainda (mostra só o rótulo)
    String? escolhido;
    if (valor.isNotEmpty) {
      escolhido = valor;
    }

    return DropdownButtonFormField<String>(
      initialValue: escolhido,
      items: itens,
      onChanged: aoMudar,
      dropdownColor: corFiltro,
      style: const TextStyle(color: corTexto, fontSize: 13),
      decoration: InputDecoration(
        labelText: rotulo,
        labelStyle: const TextStyle(color: corTextoSecundario, fontSize: 13),
        filled: true,
        fillColor: corFiltro,
        isDense: true,
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: corGrade)),
      ),
    );
  }

  // Botão que abre o calendário e mostra a data escolhida
  Widget campoData(String rotulo, String data, VoidCallback aoClicar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: const TextStyle(color: corTextoSecundario, fontSize: 12)),
        const SizedBox(height: 4),
        InkWell(
          onTap: aoClicar,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: decoracaoFiltro(),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: corTextoSecundario),
                const SizedBox(width: 8),
                Text(dataNaTela(data), style: const TextStyle(color: corTexto, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto salva, o botão fica desligado
    String textoBotao = 'Salvar';
    VoidCallback? acaoBotao = salvar;
    if (salvando) {
      textoBotao = 'Salvando...';
      acaoBotao = null;
    }

    List<Widget> filhos = [
      const Text(
        'Novo atendimento',
        style: TextStyle(color: corTexto, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 18),
      campoTexto('Cliente', campoCliente),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: campoTexto('Placa', campoPlaca)),
          const SizedBox(width: 12),
          Expanded(child: campoTexto('Modelo', campoModelo)),
          const SizedBox(width: 12),
          Expanded(child: campoTexto('Cor', campoCor)),
        ],
      ),
      const SizedBox(height: 12),
      campoTexto('O que foi feito', campoDescricao),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(flex: 3, child: campoLista('Área', area, areasServico, mudarArea)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: campoTexto('Valor (R\$)', campoValor)),
        ],
      ),
      const SizedBox(height: 12),
      campoLista('Forma de pagamento', forma, formasPagamento, mudarForma),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: campoData('Data de entrada', dataEntrada, escolherEntrada)),
          const SizedBox(width: 12),
          Expanded(child: campoData('Data de saída', dataSaida, escolherSaida)),
          const SizedBox(width: 12),
          Expanded(child: campoData('Data de pagamento', dataPagamento, escolherPagamento)),
        ],
      ),
    ];

    // Mensagem de erro (se tiver)
    if (erro.isNotEmpty) {
      filhos.add(const SizedBox(height: 12));
      filhos.add(Text(erro, style: const TextStyle(color: corErro, fontSize: 13)));
    }

    // Botões Cancelar e Salvar
    filhos.add(const SizedBox(height: 20));
    filhos.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: cancelar,
            child: const Text('Cancelar', style: TextStyle(color: corTextoSecundario)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: acaoBotao,
            style: ElevatedButton.styleFrom(
              backgroundColor: corMenuAtivo,
              foregroundColor: corTexto,
            ),
            child: Text(textoBotao),
          ),
        ],
      ),
    );

    return Dialog(
      backgroundColor: corCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: filhos,
          ),
        ),
      ),
    );
  }
}
