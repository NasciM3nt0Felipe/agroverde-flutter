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

    return maps.map((map) => EstoqueItem.fromMap(map)).toList();
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
