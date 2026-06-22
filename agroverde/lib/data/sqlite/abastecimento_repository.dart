import '../../domain/entities/abastecimento.dart';
import 'database_helper.dart';

/// Responsável pelas operações de persistência de abastecimentos.
class AbastecimentoRepository {
  /// Insere um novo abastecimento no banco.
  Future<int> inserir(Abastecimento abastecimento) async {
    final db = await DatabaseHelper.database;

    return await db.insert('abastecimento', abastecimento.toMap());
  }

  /// Atualiza os dados de um abastecimento existente.
  Future<int> atualizar(Abastecimento abastecimento) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'abastecimento',
      abastecimento.toMap(),
      where: 'id = ?',
      whereArgs: [abastecimento.id],
    );
  }

  /// Remove um abastecimento pelo identificador.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('abastecimento', where: 'id = ?', whereArgs: [id]);
  }

  /// Busca um abastecimento específico pelo ID.
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

  /// Retorna todos os abastecimentos vinculados ao veículo.
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

  /// Calcula o valor total gasto com abastecimentos do veículo.
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

  /// Calcula o total de litros abastecidos no veículo.
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
