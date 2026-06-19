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

    return await openDatabase(path, version: 1, onCreate: _onCreate);
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
      CREATE TABLE talhao (
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
      CREATE TABLE safra (
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
      CREATE TABLE estoque_item (
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

    await db.execute('''
      CREATE TABLE financeiro (
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

    await db.execute('''
      CREATE TABLE rebanho (
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

    await db.execute('''
      CREATE TABLE vacinacao_rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        vacina TEXT NOT NULL,
        data_aplicacao TEXT NOT NULL,
        proxima_dose TEXT,
        observacao TEXT,

        FOREIGN KEY(animal_id) REFERENCES rebanho(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sanitario_rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        procedimento TEXT NOT NULL,
        data TEXT NOT NULL,
        medicamento TEXT,
        observacao TEXT,

        FOREIGN KEY(animal_id) REFERENCES rebanho(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reproducao_rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        data TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(animal_id) REFERENCES rebanho(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pesagem_rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        animal_id INTEGER NOT NULL,
        peso REAL NOT NULL,
        data TEXT NOT NULL,
        observacao TEXT,

        FOREIGN KEY(animal_id) REFERENCES rebanho(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE estoque_insumo (
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
  }
}
