import '../../domain/entities/reproducao_rebanho.dart';
import 'database_helper.dart';

class ReproducaoRepository {
  Future<int> inserir(ReproducaoRebanho reproducao) async {
    final db = await DatabaseHelper.database;
    return db.insert('reproducao_rebanho', reproducao.toMap());
  }

  Future<List<ReproducaoRebanho>> listar() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'reproducao_rebanho',
      orderBy: 'id DESC',
    );

    return maps.map((map) => ReproducaoRebanho.fromMap(map)).toList();
  }

  Future<List<ReproducaoRebanho>> listarPorAnimal(int animalId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'reproducao_rebanho',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );

    return maps.map((map) => ReproducaoRebanho.fromMap(map)).toList();
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete(
      'reproducao_rebanho',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}