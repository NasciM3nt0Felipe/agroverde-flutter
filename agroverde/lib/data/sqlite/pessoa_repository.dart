import 'database_helper.dart';
import '../../domain/entities/pessoa.dart';

/// Responsável pelas operações de pessoas.
class PessoaRepository {
  /// Insere uma nova pessoa.
  Future<int> inserir(Pessoa pessoa) async {
    final db = await DatabaseHelper.database;

    return await db.insert('pessoa', pessoa.toMap());
  }

  /// Busca a pessoa vinculada ao usuário.
  Future<Pessoa?> buscarPorUsuarioId(int usuarioId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'pessoa',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Pessoa.fromMap(resultado.first);
  }

  /// Busca uma pessoa pelo ID.
  Future<Pessoa?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'pessoa',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Pessoa.fromMap(resultado.first);
  }

  /// Busca pessoa operacional pelo CPF.
  Future<Pessoa?> buscarPorCpfOperacional(String cpf) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'pessoa',
      where: 'cpf = ? AND usuario_id = ?',
      whereArgs: [cpf, 0],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Pessoa.fromMap(resultado.first);
  }

  /// Atualiza os dados de uma pessoa.
  Future<int> atualizar(Pessoa pessoa) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'pessoa',
      pessoa.toMap(),
      where: 'id = ?',
      whereArgs: [pessoa.id],
    );
  }

  /// Remove uma pessoa.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('pessoa', where: 'id = ?', whereArgs: [id]);
  }

  /// Lista todas as pessoas cadastradas.
  Future<List<Pessoa>> listarTodos() async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query('pessoa', orderBy: 'nome ASC');

    return resultado.map((map) => Pessoa.fromMap(map)).toList();
  }

  /// Lista pessoas operacionais.
  Future<List<Pessoa>> listarOperacionais() async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'pessoa',
      where: 'usuario_id = ?',
      whereArgs: [0],
      orderBy: 'nome ASC',
    );

    return resultado.map((map) => Pessoa.fromMap(map)).toList();
  }
}
