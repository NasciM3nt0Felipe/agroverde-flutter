import '../../domain/entities/veiculo.dart';
import 'database_helper.dart';

/// Responsável pelas operações de veículos.
class VeiculoRepository {
  /// Insere um novo veículo.
  Future<int> inserir(Veiculo veiculo) async {
    final db = await DatabaseHelper.database;

    return await db.insert('veiculo', veiculo.toMap());
  }

  /// Atualiza os dados do veículo.
  Future<int> atualizar(Veiculo veiculo) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'veiculo',
      veiculo.toMap(),
      where: 'id = ?',
      whereArgs: [veiculo.id],
    );
  }

  /// Remove um veículo.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('veiculo', where: 'id = ?', whereArgs: [id]);
  }

  /// Busca um veículo pelo ID.
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

  /// Lista os veículos da propriedade.
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

  /// Lista apenas veículos ativos.
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

  /// Calcula o valor total obtido com vendas.
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

  /// Retorna a quantidade de veículos cadastrados.
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
