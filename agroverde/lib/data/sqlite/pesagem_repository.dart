import '../../domain/entities/pesagem_rebanho.dart';
import 'database_helper.dart';

class PesagemRepository {
  Future<int> inserir(PesagemRebanho pesagem) async {
    final db = await DatabaseHelper.database;
    return db.insert('pesagem_rebanho', pesagem.toMap());
  }

  Future<List<PesagemRebanho>> listar() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('pesagem_rebanho', orderBy: 'id DESC');

    return maps.map((map) => PesagemRebanho.fromMap(map)).toList();
  }

  Future<List<PesagemRebanho>> listarPorAnimal(int animalId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'pesagem_rebanho',
      where: 'animal_id = ?',
      whereArgs: [animalId],
      orderBy: 'data DESC',
    );

    return maps.map((map) => PesagemRebanho.fromMap(map)).toList();
  }

  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;
    return db.delete(
      'pesagem_rebanho',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}