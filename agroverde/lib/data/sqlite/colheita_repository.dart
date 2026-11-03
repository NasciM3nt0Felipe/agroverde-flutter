import '../../domain/entities/colheita.dart';
import 'database_helper.dart';

/// Responsável pelas operações de persistência de colheitas.
class ColheitaRepository {
  /// Insere uma nova colheita no banco.
  Future<int> inserir(Colheita colheita) async {
    final db = await DatabaseHelper.database;

    return await db.insert('colheita', colheita.toMap());
  }

  /// Lista as colheitas vinculadas à propriedade selecionada.
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

  /// Verifica se a safra possui colheita registrada.
  Future<bool> existeColheitaPorSafra(int safraId) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'colheita',
      where: 'safra_id = ?',
      whereArgs: [safraId],
      limit: 1,
    );

    return maps.isNotEmpty;
  }
}
