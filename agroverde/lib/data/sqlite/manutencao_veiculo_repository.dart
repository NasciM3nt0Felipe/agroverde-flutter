import '../../domain/entities/manutencao_veiculo.dart';
import 'database_helper.dart';

/// Responsável pelas operações de manutenção de veículos.
class ManutencaoVeiculoRepository {
  /// Insere uma nova manutenção.
  Future<int> inserir(ManutencaoVeiculo manutencao) async {
    final db = await DatabaseHelper.database;

    return await db.insert('manutencao_veiculo', manutencao.toMap());
  }

  /// Atualiza os dados da manutenção.
  Future<int> atualizar(ManutencaoVeiculo manutencao) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'manutencao_veiculo',
      manutencao.toMap(),
      where: 'id = ?',
      whereArgs: [manutencao.id],
    );
  }

  /// Remove uma manutenção.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete(
      'manutencao_veiculo',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Busca uma manutenção pelo ID.
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

  /// Lista as manutenções do veículo.
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

  /// Calcula o total gasto com manutenção.
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

  /// Retorna a quantidade de manutenções registradas.
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
