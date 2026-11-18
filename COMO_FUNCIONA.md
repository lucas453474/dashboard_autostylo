# Como funciona o Dashboard Auto Stylo

Guia de estudo da Fase 1. A ideia é você conseguir explicar cada parte para a turma.

## 1. A visão geral (3 partes)

```
 NAVEGADOR (Flutter Web)          API (Dart no terminal)          MySQL
 ───────────────────────          ──────────────────────          ─────
 tela_login.dart   ──POST /login──▶ servidor.dart ──▶ funcoes.dart ──▶ Usuario
 tela_dashboard    ──GET /atendimentos──▶  (confere token)  ──▶ Fato_Servicos + JOINs
 formulario.dart   ──POST /cadastrar──▶   (transação)       ──▶ Dim_* + Fato_Servicos
        ▲                                   │
        └──────── JSON {"STATUS", "MSG"} ◀──┘
```

- **Por que existe a API?** O Flutter Web roda no navegador. Se ele falasse direto com o MySQL, a senha do banco ficaria no código que qualquer pessoa baixa. A API fica no meio: só ela sabe a senha do banco.
- **Onde ficam os cálculos?** No app, em `calculos.dart`, com `for` e acumulador. A API só entrega a lista de atendimentos. É a lógica do `main.dart` da aula, só que lendo do MySQL.

## 2. Cada arquivo

### `banco/`
| Arquivo | O que faz |
|---|---|
| `001_criar_banco.sql` | Cria o banco `auto_stylo_bi` em `utf8mb4` (por causa dos acentos). |
| *(kit)* `auto_stylo_bi_importacao_completa.sql` | Cria as 7 dimensões + a fato e carrega os 141 atendimentos (o mesmo do Power BI). |
| `002_usuario.sql` | Cria a tabela `Usuario` (`login`, `senha_hash`) e o usuário `admin`. A senha fica só como hash SHA-256. |

### `api/` (Dart de terminal: `dart run bin/servidor.dart`)
| Arquivo | O que faz |
|---|---|
| `bin/servidor.dart` | Liga o servidor na porta 8080 e decide o que fazer em cada rota (`/login`, `/atendimentos`, `/cadastrar`). Também coloca os cabeçalhos de CORS e aplica os limites. |
| `lib/conexao.dart` | Abre a conexão com o MySQL (como o meu `conexao.php`). |
| `lib/config.dart` | Os dados de conexão (host, usuário, **senha**). **Não vai para o Git.** |
| `lib/config_exemplo.dart` | Modelo do `config.dart`, sem a senha. |
| `lib/funcoes.dart` | Uma função por ação, como o meu `funcao.php`: `fazerLogin`, `listaAtendimentos`, `cadastrarAtendimento` e as auxiliares (`buscarOuCriarCliente`, `garantirData`...). |
| `lib/limite.dart` | Limite de requisições com `Map`: 5 logins por minuto e 60 requisições por minuto por IP. |

### `app/lib/` (Flutter Web: `flutter run -d chrome`)
| Arquivo | O que faz |
|---|---|
| `main.dart` | Liga o app. A `TelaInicial` empilha (Stack) o dashboard, o blur e o card de login. |
| `cores.dart` | As cores tiradas dos prints do BI. |
| `tempos.dart` | Todos os tempos das animações (em milissegundos), para ajustar num lugar só. |
| `atendimento.dart` | A classe `Atendimento`, a função `criarAtendimento(Map)` (JSON → classe) e os **dados falsos** do fundo borrado. |
| `api.dart` | As 3 chamadas para a API: `fazerLogin`, `buscarAtendimentos`, `cadastrarAtendimento`. |
| `calculos.dart` | Filtros, totais, médias, agrupamentos (top 5, por mês) e a formatação em reais. |
| `componentes.dart` | Peças visuais: caixa do gráfico, card de número, barras feitas à mão, gráfico de linha (`fl_chart`), tabela, filtro e item do menu. |
| `tela_dashboard.dart` | Menu lateral, cabeçalho com filtros, páginas Operação e Financeiro e o botão "+ Adicionar". |
| `tela_login.dart` | O card de login e a mensagem de erro. |
| `formulario.dart` | O formulário "Novo atendimento" e a `validaCampoVazio`. |

## 3. O caminho de um clique até o banco

### Login
1. O usuário digita e clica em **Entrar** → `entrar()` em `tela_login.dart`.
2. `entrar()` confere se os campos estão preenchidos e chama `fazerLogin()` (`api.dart`) → `POST /login`.
3. Na API, `tratarRequisicao()` (`servidor.dart`) confere o **limite** (`limiteGeralEstourado` e `limiteLoginEstourado`) e chama `fazerLogin()` (`funcoes.dart`).
4. `fazerLogin()` busca o `senha_hash` do usuário no MySQL (**com parâmetro**, anti SQL injection), gera o hash SHA-256 da senha digitada e compara.
5. Se bater, gera um **token** aleatório, guarda na lista `tokensValidos` e devolve `{"STATUS": 1, "MSG": "...", "token": "..."}`.
6. O app chama `buscarAtendimentos(token)` → `GET /atendimentos` (com o token no cabeçalho).
7. A API confere o token (`tokenValido`) e chama `listaAtendimentos()`, que faz o `SELECT` com os JOINs e devolve a lista.
8. O app transforma cada item em `Atendimento` (`criarListaAtendimentos`) e chama `entrou()` em `main.dart`, que faz `setState`: o blur sai e o dashboard mostra os dados reais.

### Filtro
1. O usuário escolhe "2026" em Período → `mudarPeriodo()` → `setState`.
2. O Flutter redesenha a tela: `build()` chama `filtrarAtendimentos()`, que escolhe quais atendimentos entram no `for`.
3. Todos os cards e gráficos são recalculados com a lista filtrada. **Não vai nada para a API.**

### Novo atendimento
1. "+ Adicionar" → "Novo atendimento" → `abrirFormulario()` abre o `FormularioAtendimento`.
2. **Salvar** → `salvar()`: `validaCampoVazio` em cada campo, confere o valor e chama `cadastrarAtendimento()` → `POST /cadastrar`.
3. Na API, `cadastrarAtendimento()` confere os campos e as datas (**recusa saída antes da entrada**) e abre uma **transação** (`START TRANSACTION`):
   - cliente: reaproveita pelo nome ou cria (`buscarOuCriarCliente`);
   - veículo: reaproveita pela placa ou cria (`buscarOuCriarVeiculo`);
   - serviço: cria (`criarServico`);
   - datas: se não existirem nas `Dim_Data_*`, cria (`garantirData`, com as listas de meses e dias da semana);
   - ID: o próximo do ano (`proximoIdServico`, ex.: `AS-2026-056`); os outros IDs são "maior + 1" (`proximoId`);
   - grava em `Fato_Servicos` com `Aba_Origem = 'Sistema'`.
4. Deu tudo certo → `COMMIT`. Deu erro em qualquer passo → `ROLLBACK` (nada fica gravado pela metade) e o usuário vê uma mensagem amigável. O erro técnico aparece só no terminal da API.
5. O formulário fecha, o dashboard chama `recarregarDados()` e os números se atualizam (Atendimentos vira 142).

## 4. Segurança e LGPD (resumo)
- Senha guardada só como **hash SHA-256**.
- **Consultas com parâmetros** (`:login`, `:placa`...): o valor nunca é colado no SQL.
- **Limite de requisições** por IP (`limite.dart`).
- **Token** obrigatório para ver e cadastrar dados.
- `config.dart` (senha do banco) fora do Git.
- Antes do login, o fundo borrado usa **dados falsos**: nenhum nome ou placa real chega no navegador sem login.

## 5. Perguntas que o professor pode fazer

**1. Por que vocês não conectaram o Flutter direto no MySQL?**
Porque o Flutter Web roda no navegador e todo o código dele é baixado pelo usuário. A senha do banco ficaria visível. A API em Dart fica no servidor, guarda a senha e só devolve o que o usuário logado pode ver.

**2. Como vocês garantem que os números batem com o Power BI?**
Os cálculos estão em `calculos.dart` e seguem a mesma regra do BI: total de atendimentos, soma do valor, ticket médio = total ÷ quantidade, tempo médio ignorando os 3 `Dias_Reparo` negativos, meses do Operação pela data de entrada e do Financeiro pela data de pagamento. Conferimos: 141 atendimentos, R$ 130.889,60, ticket R$ 928,30, 5,66 dias, 131 clientes.

**3. Como a senha é guardada? E se alguém roubar o banco?**
Só o hash SHA-256 fica no banco. No login, a API calcula o hash da senha digitada e compara com o guardado. Quem rouba o banco vê só o hash, não a senha.

**4. O que acontece se der erro no meio de um cadastro?**
Tudo roda numa transação. Se qualquer passo falhar (por exemplo, um texto grande demais), a API faz `ROLLBACK` e nada fica gravado pela metade: nem cliente, nem veículo, nem data. O usuário vê "Não foi possível cadastrar o atendimento" e o erro técnico aparece só no terminal.

**5. Como funciona o limite de tentativas de login?**
Em `limite.dart` existe um `Map` com o IP como chave e quantas requisições ele fez no minuto. A cada login somamos 1; se passar de 5 dentro do mesmo minuto, a API responde "Muitas tentativas de login. Espere 1 minuto." e nem consulta o banco. Passou 1 minuto, a contagem zera.

## 6. Animações (Fase 2)

A ideia é sempre a mesma: **uma variável muda com `setState` e um widget "Animated..." faz a transição sozinho**. Não usamos `AnimationController`.

### A sequência do login certo (`entrou()` em `main.dart`)
Uma variável `int fase` vai de 0 a 6. Entre uma fase e outra, `await Future.delayed(...)` espera o tempo da fase.

| Fase | O que acontece | Widget que anima |
|---|---|---|
| 0 | Card de login sobre o dashboard borrado (dados falsos) | — |
| 1 | O botão vira **✓ Login realizado** (verde) | `AnimatedContainer` (cor) |
| 2 | O card encolhe (1.0 → 0.9) e some; a logo fica | `AnimatedScale` + `AnimatedOpacity` |
| 3 | A logo cresce até ~60% da largura da tela | `AnimatedPositioned` |
| 4 | A logo encolhe e voa até o menu; o blur some; os dados reais entram (escondidos) | `AnimatedPositioned` + `TweenAnimationBuilder` (blur) |
| 5 | Menu e cabeçalho aparecem; depois os cards e gráficos, um por um | `AnimatedOpacity` + `AnimatedScale` |
| 6 | Pronto: o dashboard é liberado para clique | — |

**A logo que voa é uma cópia.** As duas logos de verdade (a do card e a do menu) têm uma `GlobalKey`, uma "etiqueta" que permite perguntar ao Flutter onde o widget está na tela (`retanguloNaTela`). A cópia começa exatamente em cima da logo do card e termina exatamente em cima da logo do menu. No mesmo `setState` em que a cópia sai, a logo do menu aparece, por isso não tem pulo.

**Os gráficos um por um:** `graficosVisiveis` é uma `List<bool>` (um item por card/gráfico, na ordem de leitura). Um `for` liga um de cada vez, com `setState` e uma espera de 80 ms. Cada card usa `aparecer(indice, ...)` em `tela_dashboard.dart`.

**Por que o blur usa `TweenAnimationBuilder` e não `AnimatedOpacity`?** Com opacidade, o `BackdropFilter` para de borrar o fundo na hora (ele passa a "enxergar" uma camada vazia). Por isso animamos a intensidade do blur (de 14 até 0).

### Outras animações
- **Login errado:** `tremer()` em `tela_login.dart` muda o deslocamento do card (12, −12, 9, −9, 5, −5, 0) com `setState`, e o `AnimatedContainer` faz o movimento.
- **Filtros:** cada barra é um `AnimatedContainer`. Quando o filtro muda, a largura (ou altura) muda e a barra desliza até o novo tamanho. O `LayoutBuilder` informa o espaço disponível para calcular o tamanho em pixels.
- **Trocar de página não repete nada:** a lista `graficosVisiveis` continua toda `true` depois do login, e cada página tem uma `ValueKey` própria (assim as barras não deslizam de uma página para a outra).

Todos os tempos ficam em `tempos.dart` (ex.: `tempoLogoCresce = 500`). Do clique até o último gráfico: ~2,7 s mais o tempo de resposta da API.

## 7. Limitações conhecidas (para não ser pego de surpresa)
- Os **tokens ficam na memória** da API: se a API reiniciar, é preciso fazer login de novo.
- Os IDs "maior + 1" funcionam bem com um usuário cadastrando por vez (é o caso da oficina).
- O **calendário** do formulário aparece em inglês, porque traduzir exige o pacote `flutter_localizations`, que não está na lista de pacotes permitidos. Os textos que nós escrevemos estão em português.
- Existem **11** áreas em `Dim_Servico.Area_Principal` (o enunciado falava em 10); o formulário usa as 11 do banco.
