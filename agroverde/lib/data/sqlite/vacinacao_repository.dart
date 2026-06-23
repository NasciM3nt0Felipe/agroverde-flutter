import '../../domain/entities/vacinacao_rebanho.dart';
import 'database_helper.dart';

class VacinacaoRepository {
  Future<int> inserir(VacinacaoRebanho vacinacao) async {
    final db = await DatabaseHelper.database;
    return db.insert('vacinacao_rebanho', vacinacao.toMap());
  }

  Future<List<VacinacaoRebanho>> listar() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('vacinacao_rebanho', orderBy: 'id DESC');

    return maps.map((map) => VacinacaoRebanho.fromMap(map)).toList();
  }

  Future<List<VacinacaoRebanho>> listarPorAnimal(int animalId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'vacinacao_rebanho',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'data_aplicacao DESC',
    );

    return maps.map((map) => VacinacaoRebanho.fromMap(map)).toList();
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete('vacinacao_rebanho', where: 'id = ?', whereArgs: [id]);
  }
}
