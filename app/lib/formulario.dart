// formulario de novo atendimento
import 'package:flutter/material.dart';

import 'api.dart';
import 'componentes.dart';
import 'cores.dart';

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

String validaCampoVazio(String valor, String nomeCampo) {
  if (valor.trim().isEmpty) {
    return 'Preencha o campo "$nomeCampo".';
  }
  return '';
}

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
  String area = '';
  String forma = '';
  List<String> datas = ['', '', ''];
  String erro = '';
  bool salvando = false;

  void mudarArea(String? valor) {
    area = valor!;
  }

  void mudarForma(String? valor) {
    forma = valor!;
  }

  Future<void> escolherData(int qual) async {
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
      return;
    }
    setState(() {
      datas[qual] = escolhida.toString().substring(0, 10);
    });
  }

  void escolherEntrada() {
    escolherData(0);
  }

  void escolherSaida() {
    escolherData(1);
  }

  void escolherPagamento() {
    escolherData(2);
  }

  void mostrarErro(String mensagem) {
    setState(() {
      erro = mensagem;
      salvando = false;
    });
  }

  Future<void> salvar() async {
    String textoValor = campoValor.text.trim();
    List<String> valores = [
      campoCliente.text,
      campoPlaca.text,
      campoModelo.text,
      campoCor.text,
      campoDescricao.text,
      area,
      textoValor,
      forma,
      datas[0],
      datas[1],
      datas[2],
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

    Map<String, dynamic> resposta = await chamarApi('cadastrar', widget.token, {
      'cliente': campoCliente.text,
      'placa': campoPlaca.text,
      'modelo': campoModelo.text,
      'cor': campoCor.text,
      'descricao': campoDescricao.text,
      'area': area,
      'valor': valor.toStringAsFixed(2),
      'formaPagamento': forma,
      'dataEntrada': datas[0],
      'dataSaida': datas[1],
      'dataPagamento': datas[2],
    });
    if (resposta['STATUS'] != 1) {
      mostrarErro(resposta['MSG'].toString());
      return;
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context, resposta['MSG'].toString());
  }

  void cancelar() {
    Navigator.pop(context);
  }

  InputDecoration decoracaoCampo(String rotulo) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(color: corTextoSecundario, fontSize: 13),
      filled: true,
      fillColor: corFiltro,
      isDense: true,
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: corGrade)),
    );
  }

  Widget campoTexto(String rotulo, TextEditingController controle) {
    return TextField(
      controller: controle,
      style: const TextStyle(color: corTexto, fontSize: 13),
      decoration: decoracaoCampo(rotulo).copyWith(
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: corMenuAtivo)),
      ),
    );
  }

  Widget campoLista(String rotulo, List<String> opcoes, ValueChanged<String?> aoMudar) {
    List<DropdownMenuItem<String>> itens = [];
    for (String opcao in opcoes) {
      itens.add(DropdownMenuItem<String>(value: opcao, child: Text(opcao)));
    }
    return DropdownButtonFormField<String>(
      items: itens,
      onChanged: aoMudar,
      dropdownColor: corFiltro,
      style: const TextStyle(color: corTexto, fontSize: 13),
      decoration: decoracaoCampo(rotulo),
    );
  }

  Widget campoData(String rotulo, String data, VoidCallback aoClicar) {
    String texto = 'Escolher data';
    if (data.isNotEmpty) {
      List<String> partes = data.split('-');
      texto = '${partes[2]}/${partes[1]}/${partes[0]}';
    }

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
                Text(texto, style: const TextStyle(color: corTexto, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          Expanded(flex: 3, child: campoLista('Área', areasServico, mudarArea)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: campoTexto('Valor (R\$)', campoValor)),
        ],
      ),
      const SizedBox(height: 12),
      campoLista('Forma de pagamento', ['DINHEIRO', 'CARTÃO', 'PIX'], mudarForma),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: campoData('Data de entrada', datas[0], escolherEntrada)),
          const SizedBox(width: 12),
          Expanded(child: campoData('Data de saída', datas[1], escolherSaida)),
          const SizedBox(width: 12),
          Expanded(child: campoData('Data de pagamento', datas[2], escolherPagamento)),
        ],
      ),
    ];
    if (erro.isNotEmpty) {
      filhos.add(const SizedBox(height: 12));
      filhos.add(Text(erro, style: const TextStyle(color: corErro, fontSize: 13)));
    }
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
