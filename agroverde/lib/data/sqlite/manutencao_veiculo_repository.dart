import '../../domain/entities/manutencao_veiculo.dart';
import 'database_helper.dart';

class ManutencaoVeiculoRepository {
  Future<int> inserir(ManutencaoVeiculo manutencao) async {
    final db = await DatabaseHelper.database;

    return await db.insert('manutencao_veiculo', manutencao.toMap());
  }

  Future<int> atualizar(ManutencaoVeiculo manutencao) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'manutencao_veiculo',
      manutencao.toMap(),
      where: 'id = ?',
      whereArgs: [manutencao.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete(
      'manutencao_veiculo',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ManutencaoVeiculo?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'manutencao_veiculo',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return ManutencaoVeiculo.fromMap(resultado.first);
  }

  Future<List<ManutencaoVeiculo>> listarPorVeiculoId(int veiculoId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'manutencao_veiculo',
      where: 'veiculo_id = ?',
      whereArgs: [veiculoId],
      orderBy: 'data DESC',
    );

    return resultado.map((e) => ManutencaoVeiculo.fromMap(e)).toList();
  }

  Future<double> totalGastoVeiculo(int veiculoId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.rawQuery(
      '''
      SELECT SUM(valor) as total
      FROM manutencao_veiculo
      WHERE veiculo_id = ?
    ''',
      [veiculoId],
    );

    return (resultado.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> quantidadeManutencoes(int veiculoId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM manutencao_veiculo
      WHERE veiculo_id = ?
    ''',
      [veiculoId],
    );

    return resultado.first['total'] as int? ?? 0;
  }
}
