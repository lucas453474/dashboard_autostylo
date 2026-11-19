// funcoes do banco
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:mysql_client/mysql_client.dart';

import 'conexao.dart';

List<String> tokensValidos = [];

List<String> nomesMeses = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];
List<String> nomesDias = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

String coluna(ResultSetRow linha, String nome) {
  String? valor = linha.colByName(nome);
  if (valor == null) {
    return '';
  }
  return valor;
}

String lerTexto(Map<String, dynamic> dados, String campo) {
  if (dados[campo] == null) {
    return '';
  }
  return dados[campo].toString().trim();
}

DateTime lerData(String texto) {
  List<String> partes = texto.split('-');
  return DateTime.utc(int.parse(partes[0]), int.parse(partes[1]), int.parse(partes[2]));
}

Future<Map<String, dynamic>> fazerLogin(String login, String senha) async {
  if (login.isEmpty || senha.isEmpty) {
    return {'STATUS': 0, 'MSG': 'Preencha o usuário e a senha.'};
  }

  try {
    MySQLConnection conexao = await abrirConexao();
    IResultSet resultado = await conexao.execute(
      'SELECT senha_hash FROM Usuario WHERE login = :login',
      {'login': login},
    );
    await conexao.close();

    String hashDigitado = sha256.convert(utf8.encode(senha)).toString();
    if (resultado.rows.isEmpty || coluna(resultado.rows.first, 'senha_hash') != hashDigitado) {
      return {'STATUS': 0, 'MSG': 'Usuário ou senha inválidos.'};
    }

    Random aleatorio = Random.secure();
    String token = '';
    for (int i = 0; i < 32; i++) {
      token += aleatorio.nextInt(256).toRadixString(16).padLeft(2, '0');
    }
    tokensValidos.add(token);
    return {'STATUS': 1, 'MSG': 'Login realizado com sucesso!', 'token': token};
  } catch (erro) {
    print('Erro no login: $erro');
    return {'STATUS': 0, 'MSG': 'Não foi possível fazer o login agora. Tente de novo.'};
  }
}

Future<Map<String, dynamic>> listaAtendimentos() async {
  try {
    MySQLConnection conexao = await abrirConexao();
    IResultSet resultado = await conexao.execute('''
      SELECT f.Cliente_ID, v.Modelo, s.Area_Principal, p.Forma_Pagamento, f.Valor, f.Dias_Reparo,
             de.AnoMes AS AnoMes_Entrada, dp.AnoMes AS AnoMes_Pagamento, de.Ano AS Ano_Entrada
      FROM Fato_Servicos f
      JOIN Dim_Veiculo v ON v.Veiculo_ID = f.Veiculo_ID
      JOIN Dim_Servico s ON s.Servico_ID = f.Servico_ID
      JOIN Dim_Pagamento p ON p.Pagamento_ID = f.Pagamento_ID
      JOIN Dim_Data_Entrada de ON de.Data_Key = f.Data_Entrada_Key
      JOIN Dim_Data_Pagamento dp ON dp.Data_Key = f.Data_Pagamento_Key
    ''');
    await conexao.close();

    List<Map<String, dynamic>> lista = [];
    for (ResultSetRow linha in resultado.rows) {
      lista.add({
        'clienteId': coluna(linha, 'Cliente_ID'),
        'modelo': coluna(linha, 'Modelo'),
        'area': coluna(linha, 'Area_Principal'),
        'formaPagamento': coluna(linha, 'Forma_Pagamento'),
        'valor': coluna(linha, 'Valor'),
        'diasReparo': coluna(linha, 'Dias_Reparo'),
        'anoMesEntrada': coluna(linha, 'AnoMes_Entrada'),
        'anoMesPagamento': coluna(linha, 'AnoMes_Pagamento'),
        'anoEntrada': coluna(linha, 'Ano_Entrada'),
      });
    }
    return {'STATUS': 1, 'MSG': '${lista.length} atendimentos encontrados.', 'DADOS': lista};
  } catch (erro) {
    print('Erro ao listar atendimentos: $erro');
    return {'STATUS': 0, 'MSG': 'Não foi possível carregar os atendimentos.'};
  }
}

Future<int> buscarId(MySQLConnection conexao, String sql, Map<String, dynamic> parametros) async {
  IResultSet resultado = await conexao.execute(sql, parametros);
  if (resultado.rows.isEmpty) {
    return 0;
  }
  return int.parse(coluna(resultado.rows.first, 'id'));
}

// ids nao sao auto increment, pega o maior e soma 1
Future<int> proximoId(MySQLConnection conexao, String tabela, String colunaId) async {
  return buscarId(conexao, 'SELECT COALESCE(MAX($colunaId), 0) + 1 AS id FROM $tabela', {});
}

Future<int> garantirData(MySQLConnection conexao, String tabela, String texto) async {
  DateTime data = lerData(texto);
  int chave = data.year * 10000 + data.month * 100 + data.day;

  int existe = await buscarId(
    conexao,
    'SELECT Data_Key AS id FROM $tabela WHERE Data_Key = :chave',
    {'chave': chave},
  );
  if (existe != 0) {
    return chave;
  }

  int trimestre = (data.month - 1) ~/ 3 + 1;
  await conexao.execute(
    'INSERT INTO $tabela (Data_Key, Data, Ano, Mes_Num, Mes, AnoMes, Trimestre, Dia, Dia_Semana) '
    'VALUES (:chave, :data, :ano, :mesNum, :mes, :anoMes, :trimestre, :dia, :diaSemana)',
    {
      'chave': chave,
      'data': texto,
      'ano': data.year,
      'mesNum': data.month,
      'mes': nomesMeses[data.month - 1],
      'anoMes': texto.substring(0, 7),
      'trimestre': 'T$trimestre',
      'dia': data.day,
      'diaSemana': nomesDias[data.weekday - 1],
    },
  );
  return chave;
}

Future<Map<String, dynamic>> cadastrarAtendimento(Map<String, dynamic> dados) async {
  String cliente = lerTexto(dados, 'cliente');
  String placa = lerTexto(dados, 'placa').toUpperCase();
  String modelo = lerTexto(dados, 'modelo').toUpperCase();
  String cor = lerTexto(dados, 'cor').toUpperCase();
  String descricao = lerTexto(dados, 'descricao');
  String area = lerTexto(dados, 'area');
  String forma = lerTexto(dados, 'formaPagamento');
  String textoValor = lerTexto(dados, 'valor');
  String entrada = lerTexto(dados, 'dataEntrada');
  String saida = lerTexto(dados, 'dataSaida');
  String pagamento = lerTexto(dados, 'dataPagamento');

  List<String> campos = [
    cliente,
    placa,
    modelo,
    cor,
    descricao,
    area,
    forma,
    textoValor,
    entrada,
    saida,
    pagamento,
  ];
  for (String campo in campos) {
    if (campo.isEmpty) {
      return {'STATUS': 0, 'MSG': 'Preencha todos os campos.'};
    }
  }

  double valor = 0;
  int diasReparo = 0;
  try {
    valor = double.parse(textoValor);
    diasReparo = lerData(saida).difference(lerData(entrada)).inDays;
    lerData(pagamento);
  } catch (erro) {
    return {'STATUS': 0, 'MSG': 'Valor ou data em formato inválido.'};
  }
  if (valor <= 0) {
    return {'STATUS': 0, 'MSG': 'O valor precisa ser maior que zero.'};
  }
  if (diasReparo < 0) {
    return {'STATUS': 0, 'MSG': 'A data de saída não pode ser antes da data de entrada.'};
  }

  MySQLConnection? conexao;
  try {
    conexao = await abrirConexao();

    int pagamentoId = await buscarId(
      conexao,
      'SELECT Pagamento_ID AS id FROM Dim_Pagamento WHERE Forma_Pagamento = :forma',
      {'forma': forma},
    );
    if (pagamentoId == 0) {
      await conexao.close();
      return {'STATUS': 0, 'MSG': 'Forma de pagamento inválida.'};
    }

    await conexao.execute('START TRANSACTION');

    int clienteId = await buscarId(
      conexao,
      'SELECT Cliente_ID AS id FROM Dim_Cliente WHERE Cliente = :nome LIMIT 1',
      {'nome': cliente},
    );
    if (clienteId == 0) {
      clienteId = await proximoId(conexao, 'Dim_Cliente', 'Cliente_ID');
      await conexao.execute('INSERT INTO Dim_Cliente (Cliente_ID, Cliente) VALUES (:id, :nome)', {
        'id': clienteId,
        'nome': cliente,
      });
    }

    int veiculoId = await buscarId(
      conexao,
      'SELECT Veiculo_ID AS id FROM Dim_Veiculo WHERE Placa = :placa LIMIT 1',
      {'placa': placa},
    );
    if (veiculoId == 0) {
      veiculoId = await proximoId(conexao, 'Dim_Veiculo', 'Veiculo_ID');
      await conexao.execute(
        'INSERT INTO Dim_Veiculo (Veiculo_ID, Placa, Modelo, Cor) VALUES (:id, :placa, :modelo, :cor)',
        {'id': veiculoId, 'placa': placa, 'modelo': modelo, 'cor': cor},
      );
    }

    int servicoId = await proximoId(conexao, 'Dim_Servico', 'Servico_ID');
    await conexao.execute(
      'INSERT INTO Dim_Servico (Servico_ID, Descricao, Area_Principal) VALUES (:id, :descricao, :area)',
      {'id': servicoId, 'descricao': descricao, 'area': area},
    );

    int ano = lerData(entrada).year;
    int numero = await buscarId(
      conexao,
      'SELECT COALESCE(MAX(CAST(SUBSTRING(ID_Servico, 9) AS UNSIGNED)), 0) + 1 AS id '
      'FROM Fato_Servicos WHERE ID_Servico LIKE :prefixo',
      {'prefixo': 'AS-$ano-%'},
    );
    String idServico = 'AS-$ano-${numero.toString().padLeft(3, '0')}';

    int chaveEntrada = await garantirData(conexao, 'Dim_Data_Entrada', entrada);
    int chaveSaida = await garantirData(conexao, 'Dim_Data_Saida', saida);
    int chavePagamento = await garantirData(conexao, 'Dim_Data_Pagamento', pagamento);

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

    await conexao.execute('COMMIT');
    await conexao.close();
    return {'STATUS': 1, 'MSG': 'Atendimento $idServico cadastrado com sucesso!'};
  } catch (erro) {
    print('Erro ao cadastrar atendimento: $erro');
    if (conexao != null) {
      await conexao.execute('ROLLBACK');
      await conexao.close();
    }
    return {'STATUS': 0, 'MSG': 'Não foi possível cadastrar o atendimento. Tente de novo.'};
  }
}
