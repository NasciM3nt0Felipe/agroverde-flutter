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

      /// Versão atual do banco.
      ///
      /// Histórico:
      /// v1 -> usuario, pessoa, propriedade
      /// v2 -> talhao
      /// v3 -> safra
      /// v4 -> correção preventiva da tabela safra
      version: 4,

      /// Executado apenas quando o banco é criado pela primeira vez.
      onCreate: _onCreate,

      /// Executado quando a versão do banco aumenta.
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

    /// Tabela de talhões.
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

    /// Tabela de safras.
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

  /// Responsável por atualizar a estrutura do banco
  /// quando uma nova versão é disponibilizada.
  ///
  /// Esse método evita apagar o banco local e preserva
  /// os dados já cadastrados.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    /// Atualização da versão 1 para a versão 2.
    ///
    /// Adiciona a tabela de talhões.
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

    /// Atualização da versão 2 para a versão 3.
    ///
    /// Adiciona a tabela de safras.
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

    /// Atualização da versão 3 para a versão 4.
    ///
    /// Correção preventiva: garante que a tabela safra exista,
    /// mesmo caso a versão 3 tenha sido aplicada antes com erro.
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
  }
}
