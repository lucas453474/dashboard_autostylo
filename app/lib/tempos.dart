// TEMPOS DAS ANIMAÇÕES (em milissegundos) — ajuste tudo aqui.
// Sequência do login certo: 500 + 300 + 500 + 600 + 100 + (4 x 80 + 350) = ~2,7 s

// 1. Botão Entrar vira "✓ Login realizado"
const int tempoBotaoOk = 500;
const int tempoCorBotao = 200; // troca de azul para verde

// 2. Card de login some (escala 1.0 -> 0.9 e opacidade -> 0), menos a logo
const int tempoCardSome = 300;

// 3. Logo cresce até ~60% da largura da tela
const int tempoLogoCresce = 500;
const double larguraLogoGrande = 0.6; // 60% da largura da tela

// 4. Logo encolhe e desliza até o menu lateral, enquanto o blur some
const int tempoLogoDesliza = 600;

// 5. Menu lateral e cabeçalho aparecem
const int tempoMolduraAparece = 300;
const int tempoAntesGraficos = 100; // espera antes do primeiro gráfico

// 6. Cards e gráficos aparecem um por um (fade + escala 0.95 -> 1.0)
const int tempoGrafico = 350;
const int intervaloGraficos = 80;

// Login errado: o card treme para os lados
const int tempoTremor = 400;

// Filtros: as barras deslizam até o novo tamanho
const int tempoBarras = 300;
