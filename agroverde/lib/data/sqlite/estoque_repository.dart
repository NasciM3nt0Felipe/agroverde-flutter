import '../../domain/entities/estoque_item.dart';
import 'database_helper.dart';

class EstoqueRepository {
  Future<int> inserir(EstoqueItem item) async {
    final db = await DatabaseHelper.database;

    return await db.insert('estoque_item', item.toMap());
  }

  Future<List<EstoqueItem>> listarPorPropriedadeId(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'estoque_item',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'nome ASC',
    );

    return maps.map((map) {
      return EstoqueItem.fromMap(map);
    }).toList();
  }

  Future<List<EstoqueItem>> listarVacinasDisponiveisPorPropriedade(
    int propriedadeId,
  ) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'estoque_item',
      where:
          'propriedade_id = ? AND LOWER(categoria) = ? AND quantidade_atual > 0',
      whereArgs: [propriedadeId, 'vacinas'],
      orderBy: 'nome ASC',
    );

    return maps.map((map) {
      return EstoqueItem.fromMap(map);
    }).toList();
  }

  Future<EstoqueItem?> buscarPorNomeCategoriaEPropriedade({
    required int propriedadeId,
    required String nome,
    required String categoria,
  }) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'estoque_item',
      where: 'propriedade_id = ? AND LOWER(nome) = ? AND LOWER(categoria) = ?',
      whereArgs: [
        propriedadeId,
        nome.trim().toLowerCase(),
        categoria.trim().toLowerCase(),
      ],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return EstoqueItem.fromMap(maps.first);
  }

  Future<int> atualizar(EstoqueItem item) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'estoque_item',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('estoque_item', where: 'id = ?', whereArgs: [id]);
  }
}
