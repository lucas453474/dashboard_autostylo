import 'package:flutter/material.dart';

import 'api.dart';
import 'atendimento.dart';
import 'componentes.dart';
import 'cores.dart';

// Card de login: logo, usuário, senha e botão Entrar
class TelaLogin extends StatefulWidget {
  // Função da tela principal, chamada quando o login dá certo
  final void Function(String token, List<Atendimento> lista) aoEntrar;

  const TelaLogin(this.aoEntrar, {super.key});

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

  // Mostra uma mensagem de erro no card
  void mostrarErro(String mensagem) {
    setState(() {
      erro = mensagem;
      carregando = false;
    });
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
    String textoBotao = 'Entrar';
    VoidCallback? acaoBotao = entrar;
    if (carregando) {
      textoBotao = 'Entrando...';
      acaoBotao = null;
    }

    // Logo, campos, mensagem de erro (se tiver) e botão
    List<Widget> filhos = [
      Image.asset('assets/logo_autostylo.png', width: 200),
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
      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: acaoBotao,
          style: ElevatedButton.styleFrom(
            backgroundColor: corMenuAtivo,
            foregroundColor: corTexto,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(
            textoBotao,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );

    return Container(
      width: 360,
      padding: const EdgeInsets.all(32),
      decoration: decoracaoCaixa(),
      child: Column(mainAxisSize: MainAxisSize.min, children: filhos),
    );
  }
}
