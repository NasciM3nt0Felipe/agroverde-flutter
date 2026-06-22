import '../../domain/entities/venda_grao.dart';
import 'database_helper.dart';

class VendaGraoRepository {
  Future<int> inserir(VendaGrao venda) async {
    final db = await DatabaseHelper.database;

    return await db.insert('venda_grao', venda.toMap());
  }

  Future<List<VendaGrao>> listarPorPropriedade(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'venda_grao',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'data_venda DESC',
    );

    return maps.map((map) => VendaGrao.fromMap(map)).toList();
  }
}
