import '../../domain/entities/animal.dart';
import 'database_helper.dart';

class RebanhoRepository {
  Future<int> inserir(Animal animal) async {
    final db = await DatabaseHelper.database;
    return db.insert('rebanho', animal.toMap());
  }

  Future<List<Animal>> listar() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('rebanho', orderBy: 'id DESC');

    return maps.map((map) => Animal.fromMap(map)).toList();
  }

  Future<int> atualizar(Animal animal) async {
    final db = await DatabaseHelper.database;

    return db.update(
      'rebanho',
      animal.toMap(),
      where: 'id = ?',
      whereArgs: [animal.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return db.delete(
      'rebanho',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}