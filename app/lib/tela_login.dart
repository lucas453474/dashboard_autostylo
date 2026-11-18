import 'package:flutter/material.dart';

import 'api.dart';
import 'atendimento.dart';
import 'componentes.dart';
import 'cores.dart';
import 'tempos.dart';

// Verde do botão depois do login certo
const Color corSucesso = Color(0xFF2EA043);

// Card de login: logo, usuário, senha e botão Entrar
class TelaLogin extends StatefulWidget {
  // Função da tela principal, chamada quando o login dá certo
  final void Function(String token, List<Atendimento> lista) aoEntrar;

  // Controles da animação (quem decide é a tela principal, em main.dart)
  final GlobalKey chaveLogo; // "etiqueta" para descobrir onde a logo do card está na tela
  final bool sucesso; // botão vira "✓ Login realizado"
  final bool sumindo; // card encolhe e some
  final bool esconderLogo; // a logo do card some (a cópia que voa fica no lugar dela)

  const TelaLogin(
    this.aoEntrar,
    this.chaveLogo,
    this.sucesso,
    this.sumindo,
    this.esconderLogo, {
    super.key,
  });

  @override
  State<TelaLogin> createState() {
    return EstadoLogin();
  }
}

class EstadoLogin extends State<TelaLogin> {
  // Os controllers guardam o que foi digitado nos campos
  TextEditingController campoLogin = TextEditingController();
  TextEditingController campoSenha = TextEditingController();
  String erro = '';
  bool carregando = false;
  double deslocamento = 0; // quanto o card está para a esquerda/direita (tremor)

  // Mostra uma mensagem de erro no card e faz o card tremer
  void mostrarErro(String mensagem) {
    setState(() {
      erro = mensagem;
      carregando = false;
    });
    tremer();
  }

  // Tremor: o card vai para os lados, cada vez menos, até voltar ao centro
  Future<void> tremer() async {
    List<double> posicoes = [12, -12, 9, -9, 5, -5, 0];
    int tempoPorPasso = tempoTremor ~/ posicoes.length; // ~/ = divisão inteira
    for (double posicao in posicoes) {
      if (!mounted) {
        return;
      }
      setState(() {
        deslocamento = posicao;
      });
      await Future.delayed(Duration(milliseconds: tempoPorPasso));
    }
  }

  // Clique em Entrar: fazerLogin() -> POST /login -> buscarAtendimentos() -> GET /atendimentos
  Future<void> entrar() async {
    // Captura os dados do formulário
    String login = campoLogin.text.trim();
    String senha = campoSenha.text;

    // Verifica se o login e a senha foram preenchidos
    if (login.isEmpty || senha.isEmpty) {
      mostrarErro('Preencha o usuário e a senha.');
      return;
    }

    setState(() {
      carregando = true;
      erro = '';
    });

    // Pede o login para a API
    Map<String, dynamic> resposta = await fazerLogin(login, senha);
    if (resposta['STATUS'] != 1) {
      mostrarErro(resposta['MSG'].toString());
      return;
    }

    // Login certo: busca os dados reais com o token
    String token = resposta['token'].toString();
    Map<String, dynamic> dados = await buscarAtendimentos(token);
    if (dados['STATUS'] != 1) {
      mostrarErro(dados['MSG'].toString());
      return;
    }

    // Avisa a tela principal (ela tira o blur e mostra o dashboard)
    widget.aoEntrar(token, criarListaAtendimentos(dados['DADOS']));
  }

  // Apertar Enter no campo de senha também faz o login
  void entrarComEnter(String texto) {
    entrar();
  }

  // Aparência dos campos de texto
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
    // Enquanto espera a API, o botão fica desligado (null) e muda o texto
    Widget textoBotao = const Text('Entrar');
    VoidCallback? acaoBotao = entrar;
    Color corBotao = corMenuAtivo;
    if (carregando) {
      textoBotao = const Text('Entrando...');
      acaoBotao = null;
    }
    // Login certo: botão verde com ✓
    if (widget.sucesso) {
      textoBotao = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(Icons.check, size: 20), SizedBox(width: 8), Text('Login realizado')],
      );
      acaoBotao = null;
      corBotao = corSucesso;
    }

    // A logo some na hora em que a cópia que voa aparece por cima (sem pulo)
    double opacidadeLogo = 1;
    if (widget.esconderLogo) {
      opacidadeLogo = 0;
    }

    // Logo, campos, mensagem de erro (se tiver) e botão
    List<Widget> filhos = [
      Opacity(
        opacity: opacidadeLogo,
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
    // AnimatedContainer: a cor do botão muda devagar (azul -> verde)
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

    // Card sumindo: escala 1.0 -> 0.9 e opacidade 1 -> 0
    double escalaCard = 1;
    double opacidadeCard = 1;
    if (widget.sumindo) {
      escalaCard = 0.9;
      opacidadeCard = 0;
    }

    // Por fora: o tremor (AnimatedContainer move o card para os lados)
    return AnimatedContainer(
      duration: Duration(milliseconds: tempoTremor ~/ 7),
      transform: Matrix4.translationValues(deslocamento, 0, 0),
      child: AnimatedOpacity(
        opacity: opacidadeCard,
        duration: const Duration(milliseconds: tempoCardSome),
        child: AnimatedScale(
          scale: escalaCard,
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
