import '../../domain/entities/abastecimento.dart';
import 'database_helper.dart';

class AbastecimentoRepository {
  Future<int> inserir(Abastecimento abastecimento) async {
    final db = await DatabaseHelper.database;

    return await db.insert('abastecimento', abastecimento.toMap());
  }

  Future<int> atualizar(Abastecimento abastecimento) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'abastecimento',
      abastecimento.toMap(),
      where: 'id = ?',
      whereArgs: [abastecimento.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('abastecimento', where: 'id = ?', whereArgs: [id]);
  }

  Future<Abastecimento?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'abastecimento',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Abastecimento.fromMap(resultado.first);
  }

  Future<List<Abastecimento>> listarPorVeiculoId(int veiculoId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'abastecimento',
      where: 'veiculo_id = ?',
      whereArgs: [veiculoId],
      orderBy: 'data DESC',
    );

    return resultado.map((e) => Abastecimento.fromMap(e)).toList();
  }

  Future<double> totalGastoVeiculo(int veiculoId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.rawQuery(
      '''
      SELECT SUM(valor_total) as total
      FROM abastecimento
      WHERE veiculo_id = ?
    ''',
      [veiculoId],
    );

    return (resultado.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> totalLitrosVeiculo(int veiculoId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.rawQuery(
      '''
      SELECT SUM(litros) as total
      FROM abastecimento
      WHERE veiculo_id = ?
    ''',
      [veiculoId],
    );

    return (resultado.first['total'] as num?)?.toDouble() ?? 0;
  }
}
