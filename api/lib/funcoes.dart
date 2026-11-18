import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:mysql_client/mysql_client.dart';

import 'conexao.dart';

// Tokens de quem já fez login (ficam só na memória da API)
List<String> tokensValidos = [];

// Listas usadas para criar uma data nova nas tabelas Dim_Data_*
List<String> nomesMeses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];
List<String> nomesDias = [
  'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo',
];

// Lê uma coluna da linha do banco como texto ('' se vier nulo)
String coluna(ResultSetRow linha, String nome) {
  String? valor = linha.colByName(nome);
  if (valor == null) {
    return '';
  }
  return valor;
}

// Lê um campo do JSON recebido como texto, já sem espaços nas pontas
String lerTexto(Map<String, dynamic> dados, String campo) {
  if (dados[campo] == null) {
    return '';
  }
  return dados[campo].toString().trim();
}

// Transforma a senha em hash SHA-256 (nunca guardamos a senha pura)
String gerarHash(String senha) {
  return sha256.convert(utf8.encode(senha)).toString();
}

// Gera um texto aleatório de 64 caracteres para ser o token
String gerarToken() {
  Random aleatorio = Random.secure();
  String token = '';
  for (int i = 0; i < 32; i++) {
    token += aleatorio.nextInt(256).toRadixString(16).padLeft(2, '0');
  }
  return token;
}

// Verifica se o token recebido é de alguém que fez login
bool tokenValido(String token) {
  return token.isNotEmpty && tokensValidos.contains(token);
}

// Converte 'aaaa-mm-dd' em DateTime (em UTC para a conta de dias não errar)
DateTime lerData(String texto) {
  List<String> partes = texto.split('-');
  return DateTime.utc(
    int.parse(partes[0]),
    int.parse(partes[1]),
    int.parse(partes[2]),
  );
}

// Escreve um DateTime como 'aaaa-mm-dd'
String escreverData(DateTime data) {
  String mes = data.month.toString().padLeft(2, '0');
  String dia = data.day.toString().padLeft(2, '0');
  return '${data.year}-$mes-$dia';
}

// LOGIN: confere o usuário e a senha e devolve um token
Future<Map<String, dynamic>> fazerLogin(String login, String senha) async {
  // Verifica se o login e a senha foram preenchidos
  if (login.isEmpty || senha.isEmpty) {
    return {'STATUS': 0, 'MSG': 'Preencha o usuário e a senha.'};
  }

  try {
    MySQLConnection conexao = await abrirConexao();

    // Busca o hash da senha do usuário
    // parâmetros: anti SQL injection
    IResultSet resultado = await conexao.execute(
      'SELECT senha_hash FROM Usuario WHERE login = :login',
      {'login': login},
    );
    await conexao.close();

    // Usuário não existe
    if (resultado.rows.isEmpty) {
      return {'STATUS': 0, 'MSG': 'Usuário ou senha inválidos.'};
    }

    // Compara o hash da senha digitada com o hash guardado
    String hashGuardado = coluna(resultado.rows.first, 'senha_hash');
    if (gerarHash(senha) != hashGuardado) {
      return {'STATUS': 0, 'MSG': 'Usuário ou senha inválidos.'};
    }

    // Login certo: cria o token e guarda na lista
    String token = gerarToken();
    tokensValidos.add(token);
    return {'STATUS': 1, 'MSG': 'Login realizado com sucesso!', 'token': token};
  } catch (erro) {
    print('Erro no login: $erro');
    return {'STATUS': 0, 'MSG': 'Não foi possível fazer o login agora. Tente de novo.'};
  }
}

// LISTAR: devolve todos os atendimentos com os JOINs já feitos
Future<Map<String, dynamic>> listaAtendimentos() async {
  try {
    MySQLConnection conexao = await abrirConexao();

    // Junta a tabela fato com todas as dimensões
    IResultSet resultado = await conexao.execute('''
      SELECT f.ID_Servico, c.Cliente, f.Cliente_ID, v.Placa, v.Modelo,
             s.Descricao, s.Area_Principal, p.Forma_Pagamento, f.Valor, f.Dias_Reparo,
             DATE_FORMAT(de.Data, '%Y-%m-%d') AS Data_Entrada, de.AnoMes AS AnoMes_Entrada,
             DATE_FORMAT(dp.Data, '%Y-%m-%d') AS Data_Pagamento, dp.AnoMes AS AnoMes_Pagamento,
             de.Ano AS Ano_Entrada
      FROM Fato_Servicos f
      JOIN Dim_Cliente c ON c.Cliente_ID = f.Cliente_ID
      JOIN Dim_Veiculo v ON v.Veiculo_ID = f.Veiculo_ID
      JOIN Dim_Servico s ON s.Servico_ID = f.Servico_ID
      JOIN Dim_Pagamento p ON p.Pagamento_ID = f.Pagamento_ID
      JOIN Dim_Data_Entrada de ON de.Data_Key = f.Data_Entrada_Key
      JOIN Dim_Data_Pagamento dp ON dp.Data_Key = f.Data_Pagamento_Key
      ORDER BY de.Data, f.ID_Servico
    ''');
    await conexao.close();

    // Monta a lista que vai virar JSON
    List<Map<String, dynamic>> lista = [];
    for (ResultSetRow linha in resultado.rows) {
      lista.add({
        'id': coluna(linha, 'ID_Servico'),
        'cliente': coluna(linha, 'Cliente'),
        'clienteId': int.parse(coluna(linha, 'Cliente_ID')),
        'placa': coluna(linha, 'Placa'),
        'modelo': coluna(linha, 'Modelo'),
        'descricao': coluna(linha, 'Descricao'),
        'area': coluna(linha, 'Area_Principal'),
        'formaPagamento': coluna(linha, 'Forma_Pagamento'),
        'valor': double.parse(coluna(linha, 'Valor')),
        'diasReparo': int.parse(coluna(linha, 'Dias_Reparo')),
        'dataEntrada': coluna(linha, 'Data_Entrada'),
        'anoMesEntrada': coluna(linha, 'AnoMes_Entrada'),
        'dataPagamento': coluna(linha, 'Data_Pagamento'),
        'anoMesPagamento': coluna(linha, 'AnoMes_Pagamento'),
        'anoEntrada': int.parse(coluna(linha, 'Ano_Entrada')),
      });
    }
    return {'STATUS': 1, 'MSG': '${lista.length} atendimentos encontrados.', 'DADOS': lista};
  } catch (erro) {
    print('Erro ao listar atendimentos: $erro');
    return {'STATUS': 0, 'MSG': 'Não foi possível carregar os atendimentos.'};
  }
}

// Pega o maior ID de uma tabela e soma 1 (os IDs não são AUTO_INCREMENT)
// O nome da tabela vem do nosso código, nunca do usuário
Future<int> proximoId(MySQLConnection conexao, String tabela, String colunaId) async {
  IResultSet resultado = await conexao.execute(
    'SELECT COALESCE(MAX($colunaId), 0) + 1 AS proximo FROM $tabela',
  );
  return int.parse(coluna(resultado.rows.first, 'proximo'));
}

// Procura o cliente pelo nome; se não existir, cria
Future<int> buscarOuCriarCliente(MySQLConnection conexao, String nome) async {
  // parâmetros: anti SQL injection
  IResultSet resultado = await conexao.execute(
    'SELECT Cliente_ID FROM Dim_Cliente WHERE Cliente = :nome LIMIT 1',
    {'nome': nome},
  );
  if (resultado.rows.isNotEmpty) {
    return int.parse(coluna(resultado.rows.first, 'Cliente_ID'));
  }

  int novoId = await proximoId(conexao, 'Dim_Cliente', 'Cliente_ID');
  // parâmetros: anti SQL injection
  await conexao.execute(
    'INSERT INTO Dim_Cliente (Cliente_ID, Cliente) VALUES (:id, :nome)',
    {'id': novoId, 'nome': nome},
  );
  return novoId;
}

// Procura o veículo pela placa; se não existir, cria
Future<int> buscarOuCriarVeiculo(
  MySQLConnection conexao,
  String placa,
  String modelo,
  String cor,
) async {
  // parâmetros: anti SQL injection
  IResultSet resultado = await conexao.execute(
    'SELECT Veiculo_ID FROM Dim_Veiculo WHERE Placa = :placa LIMIT 1',
    {'placa': placa},
  );
  if (resultado.rows.isNotEmpty) {
    return int.parse(coluna(resultado.rows.first, 'Veiculo_ID'));
  }

  int novoId = await proximoId(conexao, 'Dim_Veiculo', 'Veiculo_ID');
  // parâmetros: anti SQL injection
  await conexao.execute(
    'INSERT INTO Dim_Veiculo (Veiculo_ID, Placa, Modelo, Cor) VALUES (:id, :placa, :modelo, :cor)',
    {'id': novoId, 'placa': placa, 'modelo': modelo, 'cor': cor},
  );
  return novoId;
}

// Cria o serviço (o que foi feito + área)
Future<int> criarServico(MySQLConnection conexao, String descricao, String area) async {
  int novoId = await proximoId(conexao, 'Dim_Servico', 'Servico_ID');
  // parâmetros: anti SQL injection
  await conexao.execute(
    'INSERT INTO Dim_Servico (Servico_ID, Descricao, Area_Principal) VALUES (:id, :descricao, :area)',
    {'id': novoId, 'descricao': descricao, 'area': area},
  );
  return novoId;
}

// Procura o ID da forma de pagamento (devolve 0 se não existir)
Future<int> buscarPagamento(MySQLConnection conexao, String forma) async {
  // parâmetros: anti SQL injection
  IResultSet resultado = await conexao.execute(
    'SELECT Pagamento_ID FROM Dim_Pagamento WHERE Forma_Pagamento = :forma',
    {'forma': forma},
  );
  if (resultado.rows.isEmpty) {
    return 0;
  }
  return int.parse(coluna(resultado.rows.first, 'Pagamento_ID'));
}

// Garante que a data existe na tabela Dim_Data_* e devolve a chave (ex.: 20270115)
// O nome da tabela vem do nosso código, nunca do usuário
Future<int> garantirData(MySQLConnection conexao, String tabela, DateTime data) async {
  int chave = data.year * 10000 + data.month * 100 + data.day;

  // Se a data já existe, só devolve a chave
  // parâmetros: anti SQL injection
  IResultSet resultado = await conexao.execute(
    'SELECT Data_Key FROM $tabela WHERE Data_Key = :chave',
    {'chave': chave},
  );
  if (resultado.rows.isNotEmpty) {
    return chave;
  }

  // Monta as colunas no mesmo formato do SQL original ('Janeiro', 'T1', 'Quarta')
  String anoMes = '${data.year}-${data.month.toString().padLeft(2, '0')}';
  int trimestre = (data.month - 1) ~/ 3 + 1; // ~/ = divisão inteira
  String diaSemana = nomesDias[data.weekday - 1]; // weekday: 1 = segunda ... 7 = domingo

  // parâmetros: anti SQL injection
  await conexao.execute(
    'INSERT INTO $tabela (Data_Key, Data, Ano, Mes_Num, Mes, AnoMes, Trimestre, Dia, Dia_Semana) '
    'VALUES (:chave, :data, :ano, :mesNum, :mes, :anoMes, :trimestre, :dia, :diaSemana)',
    {
      'chave': chave,
      'data': escreverData(data),
      'ano': data.year,
      'mesNum': data.month,
      'mes': nomesMeses[data.month - 1],
      'anoMes': anoMes,
      'trimestre': 'T$trimestre',
      'dia': data.day,
      'diaSemana': diaSemana,
    },
  );
  return chave;
}

// Próximo ID_Servico do ano (ex.: AS-2026-056)
Future<String> proximoIdServico(MySQLConnection conexao, int ano) async {
  // 'AS-2026-' tem 8 letras, então o número começa na posição 9
  // parâmetros: anti SQL injection
  IResultSet resultado = await conexao.execute(
    'SELECT COALESCE(MAX(CAST(SUBSTRING(ID_Servico, 9) AS UNSIGNED)), 0) + 1 AS proximo '
    'FROM Fato_Servicos WHERE ID_Servico LIKE :prefixo',
    {'prefixo': 'AS-$ano-%'},
  );
  int numero = int.parse(coluna(resultado.rows.first, 'proximo'));
  return 'AS-$ano-${numero.toString().padLeft(3, '0')}';
}

// CADASTRAR: grava um novo atendimento (tudo dentro de UMA transação)
Future<Map<String, dynamic>> cadastrarAtendimento(Map<String, dynamic> dados) async {
  // Captura os dados do formulário
  String cliente = lerTexto(dados, 'cliente');
  String placa = lerTexto(dados, 'placa').toUpperCase();
  String modelo = lerTexto(dados, 'modelo').toUpperCase();
  String cor = lerTexto(dados, 'cor').toUpperCase();
  String descricao = lerTexto(dados, 'descricao');
  String area = lerTexto(dados, 'area');
  String forma = lerTexto(dados, 'formaPagamento');
  String textoValor = lerTexto(dados, 'valor').replaceAll(',', '.');
  String textoEntrada = lerTexto(dados, 'dataEntrada');
  String textoSaida = lerTexto(dados, 'dataSaida');
  String textoPagamento = lerTexto(dados, 'dataPagamento');

  // Verifica se algum campo veio vazio
  List<String> campos = [
    cliente, placa, modelo, cor, descricao, area, forma,
    textoValor, textoEntrada, textoSaida, textoPagamento,
  ];
  for (String campo in campos) {
    if (campo.isEmpty) {
      return {'STATUS': 0, 'MSG': 'Preencha todos os campos.'};
    }
  }

  // Confere o valor e as datas
  double valor = 0;
  DateTime dataEntrada;
  DateTime dataSaida;
  DateTime dataPagamento;
  try {
    valor = double.parse(textoValor);
    dataEntrada = lerData(textoEntrada);
    dataSaida = lerData(textoSaida);
    dataPagamento = lerData(textoPagamento);
  } catch (erro) {
    return {'STATUS': 0, 'MSG': 'Valor ou data em formato inválido.'};
  }
  if (valor <= 0) {
    return {'STATUS': 0, 'MSG': 'O valor precisa ser maior que zero.'};
  }

  // Dias de reparo = saída - entrada (recusa se a saída for antes da entrada)
  int diasReparo = dataSaida.difference(dataEntrada).inDays;
  if (diasReparo < 0) {
    return {'STATUS': 0, 'MSG': 'A data de saída não pode ser antes da data de entrada.'};
  }

  MySQLConnection? conexao;
  try {
    conexao = await abrirConexao();

    // Começa a transação: ou grava tudo, ou não grava nada
    await conexao.execute('START TRANSACTION');

    int pagamentoId = await buscarPagamento(conexao, forma);
    if (pagamentoId == 0) {
      await conexao.execute('ROLLBACK');
      await conexao.close();
      return {'STATUS': 0, 'MSG': 'Forma de pagamento inválida.'};
    }

    int clienteId = await buscarOuCriarCliente(conexao, cliente);
    int veiculoId = await buscarOuCriarVeiculo(conexao, placa, modelo, cor);
    int servicoId = await criarServico(conexao, descricao, area);
    int chaveEntrada = await garantirData(conexao, 'Dim_Data_Entrada', dataEntrada);
    int chaveSaida = await garantirData(conexao, 'Dim_Data_Saida', dataSaida);
    int chavePagamento = await garantirData(conexao, 'Dim_Data_Pagamento', dataPagamento);
    String idServico = await proximoIdServico(conexao, dataEntrada.year);

    // Grava o atendimento na tabela fato
    // parâmetros: anti SQL injection
    await conexao.execute(
      'INSERT INTO Fato_Servicos (ID_Servico, Cliente_ID, Veiculo_ID, Servico_ID, Pagamento_ID, '
      'Data_Entrada_Key, Data_Saida_Key, Data_Pagamento_Key, Valor, Dias_Reparo, Aba_Origem, Linha_Origem) '
      'VALUES (:id, :cliente, :veiculo, :servico, :pagamento, :entrada, :saida, :dataPagamento, '
      ':valor, :dias, \'Sistema\', NULL)',
      {
        'id': idServico,
        'cliente': clienteId,
        'veiculo': veiculoId,
        'servico': servicoId,
        'pagamento': pagamentoId,
        'entrada': chaveEntrada,
        'saida': chaveSaida,
        'dataPagamento': chavePagamento,
        'valor': valor.toStringAsFixed(2),
        'dias': diasReparo,
      },
    );

    // Deu tudo certo: confirma a transação
    await conexao.execute('COMMIT');
    await conexao.close();
    return {'STATUS': 1, 'MSG': 'Atendimento $idServico cadastrado com sucesso!', 'id': idServico};
  } catch (erro) {
    print('Erro ao cadastrar atendimento: $erro');

    // Algo falhou: desfaz tudo o que foi feito na transação
    if (conexao != null) {
      try {
        await conexao.execute('ROLLBACK');
        await conexao.close();
      } catch (erroRollback) {
        print('Erro no rollback: $erroRollback');
      }
    }
    return {'STATUS': 0, 'MSG': 'Não foi possível cadastrar o atendimento. Tente de novo.'};
  }
}
