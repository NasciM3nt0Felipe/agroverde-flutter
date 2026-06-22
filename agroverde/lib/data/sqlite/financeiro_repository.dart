import '../../domain/entities/lancamento_financeiro.dart';
import 'database_helper.dart';

/// Responsável pelas operações financeiras da propriedade.
class FinanceiroRepository {
  /// Insere um novo lançamento financeiro.
  Future<int> inserir(LancamentoFinanceiro lancamento) async {
    final db = await DatabaseHelper.database;

    return await db.insert('financeiro', lancamento.toMap());
  }

  /// Lista os lançamentos da propriedade.
  Future<List<LancamentoFinanceiro>> listarPorPropriedadeId(
    int propriedadeId,
  ) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'financeiro',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'id DESC',
    );

    return maps.map((map) => LancamentoFinanceiro.fromMap(map)).toList();
  }

  /// Atualiza um lançamento financeiro.
  Future<int> atualizar(LancamentoFinanceiro lancamento) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'financeiro',
      lancamento.toMap(),
      where: 'id = ? AND propriedade_id = ?',
      whereArgs: [lancamento.id, lancamento.propriedadeId],
    );
  }

  /// Remove um lançamento financeiro.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('financeiro', where: 'id = ?', whereArgs: [id]);
  }
}
