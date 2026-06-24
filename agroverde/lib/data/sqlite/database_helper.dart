import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Classe responsável por centralizar a conexão com o banco SQLite.
class DatabaseHelper {
  static Database? _database;

  /// Retorna a instância ativa do banco ou inicializa uma nova conexão.
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  /// Define o caminho físico do banco e executa a abertura do SQLite.
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'agroverde.db');

    debugPrint('Banco criado em: $path');

    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Cria todas as tabelas necessárias para uma instalação limpa do banco.
  static Future<void> _onCreate(Database db, int version) async {
    await _criarTabelas(db);
  }

  /// Aplica alterações estruturais quando o banco já existe em versão anterior.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    /// Reforça a criação das tabelas ausentes sem apagar dados existentes.
    await _criarTabelas(db);
  }

  /// Cria todas as tabelas usando IF NOT EXISTS para evitar sobrescrever dados.
  static Future<void> _criarTabelas(Database db) async {
    /// Armazena os usuários responsáveis pelo acesso ao sistema.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        senha TEXT NOT NULL
      )
    ''');

    /// Armazena os dados pessoais vinculados ao usuário.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pessoa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nome TEXT,
        cpf TEXT,
        telefone TEXT,
        cep TEXT,
        rua TEXT,
        numero TEXT,
        bairro TEXT,
        cidade TEXT,
        estado TEXT,

        FOREIGN KEY(usuario_id) REFERENCES usuario(id)
      )
    ''');

    /// Registra as propriedades rurais cadastradas por usuário.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS propriedade (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        area_total REAL NOT NULL,
        cidade TEXT,
        estado TEXT,
        descricao TEXT,

        FOREIGN KEY(usuario_id) REFERENCES usuario(id)
      )
    ''');

    /// Divide a propriedade em áreas produtivas controladas individualmente.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS talhao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        propriedade_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        area REAL NOT NULL,
        tipo_solo TEXT,
        observacao TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,

        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id)
      )
    ''');

    /// Controla o ciclo produtivo vinculado ao talhão.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS safra (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        cultura TEXT NOT NULL,
        variedade TEXT,
        data_plantio TEXT NOT NULL,
        data_colheita_prevista TEXT,
        data_colheita_real TEXT,
        producao_estimada REAL,
        producao_obtida REAL,
        status TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(talhao_id) REFERENCES talhao(id)
      )
    ''');

    /// Registra lançamentos financeiros da propriedade.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financeiro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        propriedade_id INTEGER NOT NULL,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        data TEXT NOT NULL,
        safra_id INTEGER,

        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id),
        FOREIGN KEY(safra_id) REFERENCES safra(id)
      )
    ''');

    /// Registra itens de estoque, insumos e materiais.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estoque_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        propriedade_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        categoria TEXT NOT NULL,
        quantidade_inicial REAL NOT NULL,
        quantidade_atual REAL NOT NULL,
        unidade_medida TEXT NOT NULL,
        preco_medio_unitario REAL NOT NULL,
        estoque_minimo REAL NOT NULL,
        fornecedor TEXT,
        observacao TEXT,

        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id)
      )
    ''');

    /// Registra consumo de insumos por safra.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estoque_insumo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        safra_id INTEGER NOT NULL,
        estoque_item_id INTEGER NOT NULL,
        quantidade_utilizada REAL NOT NULL,
        valor_total REAL NOT NULL,
        data_movimentacao TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(safra_id) REFERENCES safra(id),
        FOREIGN KEY(estoque_item_id) REFERENCES estoque_item(id)
      )
    ''');

    /// Registra animais vinculados à propriedade.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        propriedade_id INTEGER NOT NULL,
        identificacao TEXT NOT NULL,
        especie TEXT NOT NULL,
        raca TEXT,
        sexo TEXT NOT NULL,
        data_nascimento TEXT,
        peso REAL,
        status TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id)
      )
    ''');

    /// Registra vacinação dos animais.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vacinacao_rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        vacina TEXT NOT NULL,
        data_aplicacao TEXT NOT NULL,
        proxima_dose TEXT,
        observacao TEXT,

        FOREIGN KEY(animal_id) REFERENCES rebanho(id)
      )
    ''');

    /// Registra procedimentos sanitários dos animais.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sanitario_rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        procedimento TEXT NOT NULL,
        data TEXT NOT NULL,
        medicamento TEXT,
        observacao TEXT,

        FOREIGN KEY(animal_id) REFERENCES rebanho(id)
      )
    ''');

    /// Registra eventos reprodutivos dos animais.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reproducao_rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        data TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(animal_id) REFERENCES rebanho(id)
      )
    ''');

    /// Registra histórico de pesagem dos animais.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pesagem_rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        peso REAL NOT NULL,
        data TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(animal_id) REFERENCES rebanho(id)
      )
    ''');

    /// Registra funcionários vinculados a uma pessoa e propriedade.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS funcionario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pessoa_id INTEGER NOT NULL,
        propriedade_id INTEGER NOT NULL,
        cargo TEXT NOT NULL,
        salario REAL,
        data_contratacao TEXT,
        data_desligamento TEXT,
        status TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(pessoa_id) REFERENCES pessoa(id),
        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id)
      )
    ''');

    /// Registra a produção obtida ao finalizar uma safra.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS colheita (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        safra_id INTEGER NOT NULL,
        propriedade_id INTEGER NOT NULL,
        data_colheita TEXT NOT NULL,
        quantidade_produzida REAL NOT NULL,
        unidade TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(safra_id) REFERENCES safra(id),
        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id)
      )
    ''');

    /// Controla o saldo disponível dos grãos após a colheita.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS armazenamento_grao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        colheita_id INTEGER NOT NULL,
        propriedade_id INTEGER NOT NULL,
        produto TEXT NOT NULL,
        quantidade_total REAL NOT NULL,
        quantidade_disponivel REAL NOT NULL,
        unidade TEXT NOT NULL,
        status TEXT NOT NULL,

        FOREIGN KEY(colheita_id) REFERENCES colheita(id),
        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id)
      )
    ''');

    /// Registra vendas realizadas a partir do armazenamento de grãos.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS venda_grao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        armazenamento_id INTEGER NOT NULL,
        propriedade_id INTEGER NOT NULL,
        data_venda TEXT NOT NULL,
        comprador TEXT,
        quantidade_vendida REAL NOT NULL,
        valor_unitario REAL NOT NULL,
        valor_total REAL NOT NULL,
        unidade TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(armazenamento_id) REFERENCES armazenamento_grao(id),
        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id)
      )
    ''');

    /// Registra veículos e máquinas vinculados à propriedade.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS veiculo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        propriedade_id INTEGER NOT NULL,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        marca TEXT,
        modelo TEXT,
        ano INTEGER,
        placa TEXT,
        horimetro_odometro_atual REAL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'Ativo',
        valor_venda REAL,
        data_venda TEXT,
        observacao TEXT,

        FOREIGN KEY(propriedade_id) REFERENCES propriedade(id)
      )
    ''');

    /// Registra abastecimentos feitos em veículos ou máquinas.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS abastecimento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        veiculo_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        horimetro_odometro REAL,
        litros REAL NOT NULL,
        valor_total REAL NOT NULL,
        observacao TEXT,

        FOREIGN KEY(veiculo_id) REFERENCES veiculo(id)
      )
    ''');

    /// Registra manutenções preventivas ou corretivas dos veículos.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS manutencao_veiculo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        veiculo_id INTEGER NOT NULL,
        data TEXT NOT NULL,
        tipo TEXT NOT NULL,
        descricao TEXT,
        valor REAL NOT NULL,
        horimetro_odometro REAL,
        observacao TEXT,

        FOREIGN KEY(veiculo_id) REFERENCES veiculo(id)
      )
    ''');
  }
}
