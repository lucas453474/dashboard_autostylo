import 'dart:ui';

import 'package:flutter/material.dart';

import 'api.dart';
import 'atendimento.dart';
import 'cores.dart';
import 'tela_dashboard.dart';
import 'tela_login.dart';

void main() {
  runApp(const AppAutoStylo());
}

// O aplicativo: tema escuro igual ao BI
class AppAutoStylo extends StatelessWidget {
  const AppAutoStylo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Auto Stylo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: corFundo),
      home: const TelaInicial(),
    );
  }
}

// Tela inicial: o dashboard no fundo e, enquanto não tem login, o blur + card de login
class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() {
    return EstadoInicial();
  }
}

class EstadoInicial extends State<TelaInicial> {
  // Antes do login: dados FALSOS (nenhum nome real aparece borrado no fundo)
  List<Atendimento> atendimentos = atendimentosDeExemplo();
  String token = '';
  bool logado = false;

  // Chamada pela TelaLogin quando o login dá certo
  void entrou(String tokenRecebido, List<Atendimento> lista) {
    setState(() {
      token = tokenRecebido;
      atendimentos = lista;
      logado = true;
    });
  }

  // Busca os atendimentos de novo (usado depois de um cadastro)
  Future<void> recarregarDados() async {
    Map<String, dynamic> resposta = await buscarAtendimentos(token);
    if (resposta['STATUS'] != 1) {
      return;
    }
    setState(() {
      atendimentos = criarListaAtendimentos(resposta['DADOS']);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Camada 1: o dashboard (sem clique enquanto não tiver login)
    List<Widget> camadas = [AbsorbPointer(absorbing: !logado, child: TelaDashboard(atendimentos))];

    // Camadas 2 e 3: blur forte por cima e o card de login no meio
    if (!logado) {
      camadas.add(
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(color: const Color(0x66000000)),
          ),
        ),
      );
      camadas.add(Center(child: TelaLogin(entrou)));
    }

    return Scaffold(body: Stack(children: camadas));
  }
}
