import '../../domain/entities/talhao.dart';
import 'database_helper.dart';

class TalhaoRepository {
  Future<int> inserir(Talhao talhao) async {
    final db = await DatabaseHelper.database;
    return db.insert('talhao', talhao.toMap());
  }

  Future<List<Talhao>> listar() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('talhao', orderBy: 'nome ASC');
    return maps.map((map) => Talhao.fromMap(map)).toList();
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete('talhao', where: 'id = ?', whereArgs: [id]);
  }
}