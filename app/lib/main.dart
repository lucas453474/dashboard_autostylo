// tela inicial com blur, login e animacao da logo
import 'dart:ui';

import 'package:flutter/material.dart';

import 'api.dart';
import 'atendimento.dart';
import 'cores.dart';
import 'tela_dashboard.dart';
import 'tela_login.dart';
import 'tempos.dart';

const double blurForte = 14;

void main() {
  runApp(
    MaterialApp(
      title: 'Dashboard Auto Stylo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: corFundo,
        fontFamily: 'RobotoLocal',
      ),
      home: const TelaInicial(),
    ),
  );
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() {
    return EstadoInicial();
  }
}

Rect retanguloNaTela(GlobalKey chave) {
  RenderBox caixa = chave.currentContext!.findRenderObject() as RenderBox;
  Offset cantoDeCima = caixa.localToGlobal(Offset.zero);
  Offset cantoDeBaixo = caixa.localToGlobal(Offset(caixa.size.width, caixa.size.height));
  return Rect.fromPoints(cantoDeCima, cantoDeBaixo);
}

class EstadoInicial extends State<TelaInicial> {
  List<Atendimento> atendimentos = atendimentosDeExemplo();
  String token = '';
  int fase = 0;
  List<bool> graficosVisiveis = [true, true, true, true, true, true, true];
  GlobalKey chaveLogoCard = GlobalKey();
  GlobalKey chaveLogoMenu = GlobalKey();
  Rect logoVoando = Rect.zero;

  Future<void> esperar(int milissegundos) async {
    await Future.delayed(Duration(milliseconds: milissegundos));
  }

  Future<void> entrou(String tokenRecebido, List<Atendimento> lista) async {
    token = tokenRecebido;

    setState(() {
      fase = 1;
    });
    await esperar(tempoBotaoOk);

    setState(() {
      logoVoando = retanguloNaTela(chaveLogoCard);
      fase = 2;
    });
    await esperar(tempoCardSome);
    if (!mounted) {
      return;
    }

    Size tela = MediaQuery.sizeOf(context);
    double largura = tela.width * larguraLogoGrande;
    double altura = largura * 178 / 424;
    setState(() {
      logoVoando = Rect.fromLTWH(
        (tela.width - largura) / 2,
        (tela.height - altura) / 2,
        largura,
        altura,
      );
      fase = 3;
    });
    await esperar(tempoLogoCresce);

    setState(() {
      logoVoando = retanguloNaTela(chaveLogoMenu);
      atendimentos = lista;
      for (int i = 0; i < graficosVisiveis.length; i++) {
        graficosVisiveis[i] = false;
      }
      fase = 4;
    });
    await esperar(tempoLogoDesliza);

    setState(() {
      fase = 5;
    });
    await esperar(tempoAntesGraficos);

    for (int i = 0; i < graficosVisiveis.length; i++) {
      setState(() {
        graficosVisiveis[i] = true;
      });
      await esperar(intervaloGraficos);
    }
    await esperar(tempoGrafico);
    setState(() {
      fase = 6;
    });
  }

  Future<void> recarregarDados() async {
    Map<String, dynamic> resposta = await chamarApi('atendimentos', token, {});
    if (resposta['STATUS'] != 1) {
      return;
    }
    setState(() {
      atendimentos = criarListaAtendimentos(resposta['DADOS']);
    });
  }

  // com opacidade o blur para de borrar, entao anima o sigma
  Widget desenharBlur(BuildContext context, double intensidade, Widget? filho) {
    double escuro = 0.4 * intensidade / blurForte;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: intensidade, sigmaY: intensidade),
      child: Container(color: Color.fromRGBO(0, 0, 0, escuro)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double intensidadeBlur = blurForte;
    if (fase >= 4) {
      intensidadeBlur = 0;
    }
    int tempoDaLogo = 0;
    if (fase == 3) {
      tempoDaLogo = tempoLogoCresce;
    } else if (fase == 4) {
      tempoDaLogo = tempoLogoDesliza;
    }

    List<Widget> camadas = [
      AbsorbPointer(
        absorbing: fase < 6,
        child: TelaDashboard(
          atendimentos,
          token,
          recarregarDados,
          chaveLogoMenu,
          fase,
          graficosVisiveis,
        ),
      ),
    ];

    if (fase < 5) {
      camadas.add(
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: blurForte, end: intensidadeBlur),
            duration: const Duration(milliseconds: tempoLogoDesliza),
            builder: desenharBlur,
          ),
        ),
      );
    }

    if (fase < 3) {
      camadas.add(Center(child: TelaLogin(entrou, chaveLogoCard, fase)));
    }

    if (fase >= 2 && fase <= 4) {
      camadas.add(
        AnimatedPositioned(
          duration: Duration(milliseconds: tempoDaLogo),
          curve: Curves.easeInOut,
          left: logoVoando.left,
          top: logoVoando.top,
          width: logoVoando.width,
          height: logoVoando.height,
          child: Image.asset('assets/logo_autostylo.png', fit: BoxFit.contain),
        ),
      );
    }

    return Scaffold(body: Stack(children: camadas));
  }
}
