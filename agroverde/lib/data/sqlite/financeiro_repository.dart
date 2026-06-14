import '../../domain/entities/lancamento_financeiro.dart';
import 'database_helper.dart';

class FinanceiroRepository {
  Future<int> inserir(LancamentoFinanceiro lancamento) async {
    final db = await DatabaseHelper.database;

    return await db.insert('financeiro', lancamento.toMap());
  }

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

  Future<int> atualizar(LancamentoFinanceiro lancamento) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'financeiro',
      lancamento.toMap(),
      where: 'id = ? AND propriedade_id = ?',
      whereArgs: [lancamento.id, lancamento.propriedadeId],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('financeiro', where: 'id = ?', whereArgs: [id]);
  }
}
