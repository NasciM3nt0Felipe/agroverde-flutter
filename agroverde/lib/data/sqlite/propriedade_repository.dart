import '../../domain/entities/propriedade.dart';
import 'database_helper.dart';

class PropriedadeRepository {
  Future<int> inserir(Propriedade propriedade) async {
    final db = await DatabaseHelper.database;

    return await db.insert('propriedade', propriedade.toMap());
  }

  Future<List<Propriedade>> listarPorUsuarioId(int usuarioId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'propriedade',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );

    return resultado.map((map) => Propriedade.fromMap(map)).toList();
  }

  Future<int> atualizar(Propriedade propriedade) async {
    final db = await DatabaseHelper.database;

    final dados = propriedade.toMap();

    return await db.update(
      'propriedade',
      dados,
      where: 'id = ?',
      whereArgs: [propriedade.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('propriedade', where: 'id = ?', whereArgs: [id]);
  }

  Future<Propriedade?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'propriedade',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Propriedade.fromMap(resultado.first);
  }
}
