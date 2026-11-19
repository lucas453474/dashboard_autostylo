// tela de login
import 'package:flutter/material.dart';

import 'api.dart';
import 'atendimento.dart';
import 'componentes.dart';
import 'cores.dart';
import 'tempos.dart';

class TelaLogin extends StatefulWidget {
  final void Function(String token, List<Atendimento> lista) aoEntrar;
  final GlobalKey chaveLogo;
  final int fase;

  const TelaLogin(this.aoEntrar, this.chaveLogo, this.fase, {super.key});

  @override
  State<TelaLogin> createState() {
    return EstadoLogin();
  }
}

class EstadoLogin extends State<TelaLogin> {
  TextEditingController campoLogin = TextEditingController();
  TextEditingController campoSenha = TextEditingController();
  String erro = '';
  bool carregando = false;
  double deslocamento = 0;

  Future<void> mostrarErro(String mensagem) async {
    setState(() {
      erro = mensagem;
      carregando = false;
    });

    List<double> posicoes = [12, -12, 9, -9, 5, -5, 0];
    for (double posicao in posicoes) {
      setState(() {
        deslocamento = posicao;
      });
      await Future.delayed(const Duration(milliseconds: tempoTremor ~/ 7));
    }
  }

  Future<void> entrar() async {
    String login = campoLogin.text.trim();
    String senha = campoSenha.text;
    if (login.isEmpty || senha.isEmpty) {
      mostrarErro('Preencha o usuário e a senha.');
      return;
    }

    setState(() {
      carregando = true;
      erro = '';
    });

    Map<String, dynamic> resposta = await chamarApi('login', '', {'login': login, 'senha': senha});
    if (resposta['STATUS'] != 1) {
      mostrarErro(resposta['MSG'].toString());
      return;
    }

    String token = resposta['token'].toString();
    Map<String, dynamic> dados = await chamarApi('atendimentos', token, {});
    if (dados['STATUS'] != 1) {
      mostrarErro(dados['MSG'].toString());
      return;
    }

    widget.aoEntrar(token, criarListaAtendimentos(dados['DADOS']));
  }

  void entrarComEnter(String texto) {
    entrar();
  }

  InputDecoration decoracaoCampo(String rotulo, IconData icone) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(color: corTextoSecundario),
      prefixIcon: Icon(icone, color: corTextoSecundario, size: 18),
      filled: true,
      fillColor: corFiltro,
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: corGrade)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: corMenuAtivo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool sucesso = widget.fase >= 1;
    bool sumindo = widget.fase >= 2;

    Widget textoBotao = const Text('Entrar');
    VoidCallback? acaoBotao = entrar;
    Color corBotao = corMenuAtivo;
    if (carregando) {
      textoBotao = const Text('Entrando...');
      acaoBotao = null;
    }
    if (sucesso) {
      textoBotao = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(Icons.check, size: 20), SizedBox(width: 8), Text('Login realizado')],
      );
      acaoBotao = null;
      corBotao = corSucesso;
    }

    double opacidade = 1;
    double escala = 1;
    if (sumindo) {
      opacidade = 0;
      escala = 0.9;
    }

    List<Widget> filhos = [
      Opacity(
        opacity: opacidade,
        child: Image.asset('assets/logo_autostylo.png', width: 200, key: widget.chaveLogo),
      ),
      const SizedBox(height: 28),
      TextField(
        controller: campoLogin,
        style: const TextStyle(color: corTexto),
        decoration: decoracaoCampo('Usuário', Icons.person_outline),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: campoSenha,
        obscureText: true,
        style: const TextStyle(color: corTexto),
        decoration: decoracaoCampo('Senha', Icons.lock_outline),
        onSubmitted: entrarComEnter,
      ),
    ];
    if (erro.isNotEmpty) {
      filhos.add(const SizedBox(height: 12));
      filhos.add(Text(erro, style: const TextStyle(color: corErro, fontSize: 13)));
    }
    filhos.add(const SizedBox(height: 20));
    filhos.add(
      AnimatedContainer(
        duration: const Duration(milliseconds: tempoCorBotao),
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(color: corBotao, borderRadius: BorderRadius.circular(6)),
        child: TextButton(
          onPressed: acaoBotao,
          style: TextButton.styleFrom(
            foregroundColor: corTexto,
            disabledForegroundColor: corTexto,
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          child: textoBotao,
        ),
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: tempoTremor ~/ 7),
      transform: Matrix4.translationValues(deslocamento, 0, 0),
      child: AnimatedOpacity(
        opacity: opacidade,
        duration: const Duration(milliseconds: tempoCardSome),
        child: AnimatedScale(
          scale: escala,
          duration: const Duration(milliseconds: tempoCardSome),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(32),
            decoration: decoracaoCaixa(),
            child: Column(mainAxisSize: MainAxisSize.min, children: filhos),
          ),
        ),
      ),
    );
  }
}
