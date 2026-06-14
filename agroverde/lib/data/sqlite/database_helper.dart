import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'agroverde.db');
    debugPrint('Banco criado em: $path');

    return await openDatabase(
      path,
      version: 3,
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

    await _createFinanceiroTables(db);
    await _createRebanhoTables(db);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createFinanceiroTables(db);
    }

    if (oldVersion < 3) {
      await _createRebanhoTables(db);
    }
  }

  static Future<void> _createFinanceiroTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS talhao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        area REAL NOT NULL,
        descricao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS safra (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cultura TEXT NOT NULL,
        ano INTEGER NOT NULL,
        talhao_id INTEGER,
        FOREIGN KEY(talhao_id) REFERENCES talhao(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS financeiro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descricao TEXT NOT NULL,
        valor REAL NOT NULL,
        tipo TEXT NOT NULL,
        data TEXT NOT NULL,
        safra_id INTEGER,
        FOREIGN KEY(safra_id) REFERENCES safra(id)
      )
    ''');
  }

  static Future<void> _createRebanhoTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rebanho (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        identificacao TEXT NOT NULL,
        especie TEXT NOT NULL,
        raca TEXT,
        sexo TEXT NOT NULL,
        data_nascimento TEXT,
        peso REAL,
        status TEXT NOT NULL,
        observacao TEXT
      )
    ''');

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
  }
}