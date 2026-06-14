import '../../domain/entities/lancamento_financeiro.dart';
import 'database_helper.dart';

class FinanceiroRepository {
  Future<int> inserir(LancamentoFinanceiro lancamento) async {
    final db = await DatabaseHelper.database;
    return db.insert('financeiro', lancamento.toMap());
  }

  Future<List<LancamentoFinanceiro>> listar() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('financeiro', orderBy: 'id DESC');

    return maps.map((map) => LancamentoFinanceiro.fromMap(map)).toList();
  }

  Future<int> atualizar(LancamentoFinanceiro lancamento) async {
    final db = await DatabaseHelper.database;
    return db.update(
      'financeiro',
      lancamento.toMap(),
      where: 'id = ?',
      whereArgs: [lancamento.id],
    );
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete('financeiro', where: 'id = ?', whereArgs: [id]);
  }
}