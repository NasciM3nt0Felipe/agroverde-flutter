import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'agroverde.db');

    debugPrint('Banco criado em: $path');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        senha TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pessoa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER,
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

    await db.execute('''
      CREATE TABLE propriedade (
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

        FOREIGN KEY(armazenamento_id)
          REFERENCES armazenamento_grao(id),
        FOREIGN KEY(propriedade_id)
          REFERENCES propriedade(id)
      )
    ''');
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

   valor_venda REAL DEFAULT 0,
    data_venda TEXT,

    observacao TEXT,

    FOREIGN KEY(propriedade_id)
      REFERENCES propriedade(id)
  )
''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS abastecimento (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    veiculo_id INTEGER NOT NULL,

    data TEXT NOT NULL,

    horimetro_odometro REAL,

    litros REAL NOT NULL,

    valor_total REAL NOT NULL,

    observacao TEXT,

    FOREIGN KEY(veiculo_id)
      REFERENCES veiculo(id)
  )
''');

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

    FOREIGN KEY(veiculo_id)
      REFERENCES veiculo(id)
  )
''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
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
    }

    if (oldVersion < 3) {
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
    }

    if (oldVersion < 4) {
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
    }

    if (oldVersion < 5) {
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
    }

    if (oldVersion < 6) {
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

          FOREIGN KEY(armazenamento_id)
            REFERENCES armazenamento_grao(id),
          FOREIGN KEY(propriedade_id)
            REFERENCES propriedade(id)
        )
      ''');
    }

    if (oldVersion < 7) {
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

      FOREIGN KEY(propriedade_id)
        REFERENCES propriedade(id)
    )
  ''');

      await db.execute('''
    CREATE TABLE IF NOT EXISTS abastecimento (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      veiculo_id INTEGER NOT NULL,

      data TEXT NOT NULL,

      horimetro_odometro REAL,

      litros REAL NOT NULL,

      valor_total REAL NOT NULL,

      observacao TEXT,

      FOREIGN KEY(veiculo_id)
        REFERENCES veiculo(id)
    )
  ''');

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

      FOREIGN KEY(veiculo_id)
        REFERENCES veiculo(id)
    )
  ''');
    }
  }
}
