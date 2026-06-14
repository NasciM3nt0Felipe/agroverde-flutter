import '../../domain/entities/animal.dart';
import 'database_helper.dart';

class RebanhoRepository {
  Future<int> inserir(Animal animal) async {
    final db = await DatabaseHelper.database;

    return await db.insert('rebanho', animal.toMap());
  }

  /// Mantido por compatibilidade com as páginas antigas do Maicon.
  /// Depois podemos trocar essas páginas para usar listarPorPropriedadeId.
  Future<List<Animal>> listar() async {
    final db = await DatabaseHelper.database;

    final maps = await db.query('rebanho', orderBy: 'id DESC');

    return maps.map((map) => Animal.fromMap(map)).toList();
  }

  Future<List<Animal>> listarPorPropriedadeId(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'rebanho',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'id DESC',
    );

    return maps.map((map) => Animal.fromMap(map)).toList();
  }

  Future<int> atualizar(Animal animal) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'rebanho',
      animal.toMap(),
      where: 'id = ? AND propriedade_id = ?',
      whereArgs: [animal.id, animal.propriedadeId],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('rebanho', where: 'id = ?', whereArgs: [id]);
  }
}
