import '../../domain/entities/sanitario_rebanho.dart';
import 'database_helper.dart';

class SanitarioRepository {
  Future<int> inserir(SanitarioRebanho sanitario) async {
    final db = await DatabaseHelper.database;
    return db.insert('sanitario_rebanho', sanitario.toMap());
  }

  Future<List<SanitarioRebanho>> listar() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('sanitario_rebanho', orderBy: 'id DESC');

    return maps.map((map) => SanitarioRebanho.fromMap(map)).toList();
  }

  Future<List<SanitarioRebanho>> listarPorAnimal(int animalId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'sanitario_rebanho',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );

    return maps.map((map) => SanitarioRebanho.fromMap(map)).toList();
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete('sanitario_rebanho', where: 'id = ?', whereArgs: [id]);
  }
}
