import 'dart:ui';

import 'package:flutter/material.dart';

import 'api.dart';
import 'atendimento.dart';
import 'cores.dart';
import 'tela_dashboard.dart';
import 'tela_login.dart';
import 'tempos.dart';

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
      // fontFamily: a fonte que vem dentro do app (pubspec.yaml), para não depender da internet
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: corFundo,
        fontFamily: 'RobotoLocal',
      ),
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

// Proporção da imagem da logo (424 x 178 pixels): altura = largura x proporção
const double proporcaoLogo = 178 / 424;

// Intensidade do blur antes do login (forte, para não dar para ler nada)
const double blurForte = 14;

// Descobre o retângulo (posição e tamanho) de um widget na tela, pela GlobalKey dele
Rect retanguloNaTela(GlobalKey chave) {
  BuildContext? contexto = chave.currentContext;
  if (contexto == null) {
    return Rect.zero;
  }
  RenderBox caixa = contexto.findRenderObject() as RenderBox;
  // localToGlobal converte "canto do widget" em "ponto da tela" (já conta o FittedBox)
  Offset cantoDeCima = caixa.localToGlobal(Offset.zero);
  Offset cantoDeBaixo = caixa.localToGlobal(Offset(caixa.size.width, caixa.size.height));
  return Rect.fromPoints(cantoDeCima, cantoDeBaixo);
}

class EstadoInicial extends State<TelaInicial> {
  // Antes do login: dados FALSOS (nenhum nome real aparece borrado no fundo)
  List<Atendimento> atendimentos = atendimentosDeExemplo();
  String token = '';

  // FASES DA ANIMAÇÃO (trocadas com setState + Future.delayed):
  // 0 = card de login | 1 = botão ✓ | 2 = card some, logo fica | 3 = logo cresce
  // 4 = logo vai para o menu e o blur some | 5 = menu, cabeçalho e gráficos aparecem
  // 6 = pronto (dashboard liberado para clique)
  int fase = 0;

  // Um bool para cada card/gráfico, na ordem de leitura (a página Financeiro tem 7)
  List<bool> graficosVisiveis = [true, true, true, true, true, true, true];

  // As "etiquetas" das duas logos de verdade (a do card e a do menu)
  GlobalKey chaveLogoCard = GlobalKey();
  GlobalKey chaveLogoMenu = GlobalKey();

  // Onde a cópia da logo (a que voa) está agora
  Rect logoVoando = Rect.zero;

  // Espera um tempo (em milissegundos)
  Future<void> esperar(int milissegundos) async {
    await Future.delayed(Duration(milliseconds: milissegundos));
  }

  // Chamada pela TelaLogin quando o login dá certo: roda a sequência da animação
  Future<void> entrou(String tokenRecebido, List<Atendimento> lista) async {
    token = tokenRecebido;

    // 1. O botão Entrar vira "✓ Login realizado"
    setState(() {
      fase = 1;
    });
    await esperar(tempoBotaoOk);

    // 2. O card some; a cópia da logo aparece exatamente em cima da logo do card
    Rect logoDoCard = retanguloNaTela(chaveLogoCard);
    setState(() {
      logoVoando = logoDoCard;
      fase = 2;
    });
    await esperar(tempoCardSome);
    if (!mounted) {
      return;
    }

    // 3. A logo cresce no centro da tela (o blur forte continua no fundo)
    Size tela = MediaQuery.sizeOf(context);
    double largura = tela.width * larguraLogoGrande;
    double altura = largura * proporcaoLogo;
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

    // 4. A logo encolhe e desliza até o lugar EXATO da logo do menu; o blur some.
    //    Ao mesmo tempo trocamos os dados falsos pelos reais e escondemos
    //    menu, cabeçalho e gráficos (eles somem antes do blur acabar de sair)
    Rect logoDoMenu = retanguloNaTela(chaveLogoMenu);
    setState(() {
      logoVoando = logoDoMenu;
      atendimentos = lista;
      for (int i = 0; i < graficosVisiveis.length; i++) {
        graficosVisiveis[i] = false;
      }
      fase = 4;
    });
    await esperar(tempoLogoDesliza);

    // 5. A cópia chegou: no MESMO setState ela sai e a logo do menu aparece (sem pulo).
    //    Menu e cabeçalho aparecem
    setState(() {
      fase = 5;
    });
    await esperar(tempoAntesGraficos);

    // 6. Os cards e gráficos aparecem um por um, na ordem de leitura
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

  // Desenha o blur com a intensidade do momento (de 0 = sem blur até blurForte).
  // O TweenAnimationBuilder chama esta função a cada quadro, com a intensidade mudando aos poucos.
  // (Não dá para usar AnimatedOpacity aqui: com opacidade, o blur para de borrar o fundo)
  Widget desenharBlur(BuildContext context, double intensidade, Widget? filho) {
    double escuro = 0.4 * intensidade / blurForte; // o fundo escuro some junto com o blur
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: intensidade, sigmaY: intensidade),
      child: Container(color: Color.fromRGBO(0, 0, 0, escuro)),
    );
  }

  // A cópia da logo muda de velocidade conforme a fase
  int tempoDaLogo() {
    if (fase == 3) {
      return tempoLogoCresce;
    }
    if (fase == 4) {
      return tempoLogoDesliza;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // O que aparece em cada fase
    bool mostrarLogoMenu = fase <= 1 || fase >= 5;
    bool mostrarMoldura = fase <= 3 || fase >= 5;
    double intensidadeBlur = blurForte;
    if (fase >= 4) {
      intensidadeBlur = 0;
    }

    // Camada 1: o dashboard (sem clique até a animação terminar)
    List<Widget> camadas = [
      AbsorbPointer(
        absorbing: fase < 6,
        child: TelaDashboard(
          atendimentos,
          token,
          recarregarDados,
          chaveLogoMenu,
          mostrarLogoMenu,
          mostrarMoldura,
          graficosVisiveis,
        ),
      ),
    ];

    // Camada 2: blur forte por cima (some devagar na fase 4)
    if (fase < 5) {
      camadas.add(
        Positioned.fill(
          // begin só vale na primeira vez; depois ele anima do valor atual até o end
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: blurForte, end: intensidadeBlur),
            duration: const Duration(milliseconds: tempoLogoDesliza),
            builder: desenharBlur,
          ),
        ),
      );
    }

    // Camada 3: o card de login (até ele sumir)
    if (fase < 3) {
      camadas.add(Center(child: TelaLogin(entrou, chaveLogoCard, fase >= 1, fase >= 2, fase >= 2)));
    }

    // Camada 4: a cópia da logo que voa, por cima de tudo (fases 2, 3 e 4)
    if (fase >= 2 && fase <= 4) {
      camadas.add(
        AnimatedPositioned(
          duration: Duration(milliseconds: tempoDaLogo()),
          curve: Curves.easeInOut,
          left: logoVoando.left,
          top: logoVoando.top,
          width: logoVoando.width,
          height: logoVoando.height,
          // fit: contain = a imagem estica até o tamanho da caixa (sem isso ela não cresce)
          child: Image.asset('assets/logo_autostylo.png', fit: BoxFit.contain),
        ),
      );
    }

    return Scaffold(body: Stack(children: camadas));
  }
}
