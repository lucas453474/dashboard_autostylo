import 'package:flutter/animation.dart';

// TEMPOS DAS ANIMAÇÕES (em milissegundos) — ajuste tudo aqui.
// Sequência do login certo: 500 + 240 + 500 + 600 + 100 + (6 x 80 + 400) = ~2,8 s

// 1. Botão Entrar vira "✓ Login realizado"
const int tempoBotaoOk = 500;
const int tempoCorBotao = 200; // troca de azul para verde (e o texto troca com fade)

// 2. Card de login some (escala 1.0 -> 0.96 e opacidade -> 0), menos a logo.
//    Saída é mais rápida que entrada: o que sai não deve segurar a atenção.
const int tempoCardSome = 240;

// 3. Logo cresce até ~60% da largura da tela
const int tempoLogoCresce = 500;
const double larguraLogoGrande = 0.6; // 60% da largura da tela

// 4. Logo encolhe e desliza até o menu lateral, enquanto o blur some
const int tempoLogoDesliza = 600;

// 5. Menu lateral e cabeçalho aparecem
const int tempoMolduraAparece = 300;
const int tempoAntesGraficos = 100; // espera antes do primeiro gráfico

// 6. Cards e gráficos aparecem um por um (fade + sobem 12 px + escala 0.98 -> 1.0)
const int tempoGrafico = 400;
const int intervaloGraficos = 80;

// Login errado: o card treme para os lados
const int tempoTremor = 400;

// Filtros: as barras e a linha deslizam até o novo tamanho
const int tempoBarras = 350;

// Troca de página no menu (Operação <-> Financeiro): troca com fade
const int tempoTrocaPagina = 200;

// Item do menu e respostas a clique (fundo, barrinha)
const int tempoClique = 150;

// CURVAS (o "jeito" de acelerar/frear). Regras:
// - Entrada: começa rápido e freia no fim (ease-out). Parece responder na hora.
// - Saída: começa devagar e acelera (ease-in). Sai do caminho sem chamar atenção.
// - Algo que já está na tela e vai para outro lugar: ease-in-out.
// - Nada de "quique" (bounce/elastic): parece brinquedo e envelhece rápido.
const Curve curvaEntrada = Curves.easeOutQuart;
const Curve curvaSaida = Curves.easeInCubic;
const Curve curvaMovimento = Curves.easeInOutCubic;
