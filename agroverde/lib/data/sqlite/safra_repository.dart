import '../../domain/entities/safra.dart';
import 'database_helper.dart';

class SafraRepository {
  Future<int> inserir(Safra safra) async {
    final db = await DatabaseHelper.database;
    return db.insert('safra', safra.toMap());
  }

  Future<List<Safra>> listar() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('safra', orderBy: 'ano DESC');
    return maps.map((map) => Safra.fromMap(map)).toList();
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete('safra', where: 'id = ?', whereArgs: [id]);
  }
}