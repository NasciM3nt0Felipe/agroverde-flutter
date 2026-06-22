import '../../domain/entities/colheita.dart';
import 'database_helper.dart';

class ColheitaRepository {
  Future<int> inserir(Colheita colheita) async {
    final db = await DatabaseHelper.database;

    return await db.insert('colheita', colheita.toMap());
  }

  Future<List<Colheita>> listarPorPropriedade(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'colheita',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'data_colheita DESC',
    );

    return maps.map((map) => Colheita.fromMap(map)).toList();
  }
}
