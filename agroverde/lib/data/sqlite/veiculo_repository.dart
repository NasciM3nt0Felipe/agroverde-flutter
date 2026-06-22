import '../../domain/entities/veiculo.dart';
import 'database_helper.dart';

class VeiculoRepository {
  Future<int> inserir(Veiculo veiculo) async {
    final db = await DatabaseHelper.database;

    return await db.insert('veiculo', veiculo.toMap());
  }

  Future<int> atualizar(Veiculo veiculo) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'veiculo',
      veiculo.toMap(),
      where: 'id = ?',
      whereArgs: [veiculo.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('veiculo', where: 'id = ?', whereArgs: [id]);
  }

  Future<Veiculo?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'veiculo',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Veiculo.fromMap(resultado.first);
  }

  Future<List<Veiculo>> listarPorPropriedadeId(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'veiculo',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'nome ASC',
    );

    return resultado.map((e) => Veiculo.fromMap(e)).toList();
  }

  Future<List<Veiculo>> listarAtivosPorPropriedadeId(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'veiculo',
      where: 'propriedade_id = ? AND status != ?',
      whereArgs: [propriedadeId, 'Vendido'],
      orderBy: 'nome ASC',
    );

    return resultado.map((e) => Veiculo.fromMap(e)).toList();
  }

  Future<double> totalVendidoPorPropriedade(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.rawQuery(
      '''
      SELECT SUM(valor_venda) as total
      FROM veiculo
      WHERE propriedade_id = ?
    ''',
      [propriedadeId],
    );

    return (resultado.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> totalVeiculos(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM veiculo
      WHERE propriedade_id = ?
    ''',
      [propriedadeId],
    );

    return resultado.first['total'] as int;
  }
}
