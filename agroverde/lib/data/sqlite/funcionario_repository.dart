import '../../domain/entities/funcionario.dart';
import 'database_helper.dart';

class FuncionarioRepository {
  Future<int> inserir(Funcionario funcionario) async {
    final db = await DatabaseHelper.database;

    return await db.insert('funcionario', funcionario.toMap());
  }

  Future<int> atualizar(Funcionario funcionario) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'funcionario',
      funcionario.toMap(),
      where: 'id = ?',
      whereArgs: [funcionario.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('funcionario', where: 'id = ?', whereArgs: [id]);
  }

  Future<Funcionario?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'funcionario',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Funcionario.fromMap(resultado.first);
  }

  Future<List<Funcionario>> listarPorPropriedadeId(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'funcionario',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'status ASC, cargo ASC',
    );

    return resultado.map((map) => Funcionario.fromMap(map)).toList();
  }

  Future<List<Funcionario>> listarAtivosPorPropriedadeId(
    int propriedadeId,
  ) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'funcionario',
      where: 'propriedade_id = ? AND status = ?',
      whereArgs: [propriedadeId, 'Ativo'],
      orderBy: 'cargo ASC',
    );

    return resultado.map((map) => Funcionario.fromMap(map)).toList();
  }

  Future<List<Funcionario>> listarTodos() async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'funcionario',
      orderBy: 'status ASC, cargo ASC',
    );

    return resultado.map((map) => Funcionario.fromMap(map)).toList();
  }

  Future<bool> existeFuncionarioParaPessoa(
    int pessoaId,
    int propriedadeId,
  ) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'funcionario',
      where: 'pessoa_id = ? AND propriedade_id = ?',
      whereArgs: [pessoaId, propriedadeId],
      limit: 1,
    );

    return resultado.isNotEmpty;
  }
}
