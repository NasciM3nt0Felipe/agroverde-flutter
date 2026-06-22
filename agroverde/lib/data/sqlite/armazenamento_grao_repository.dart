import '../../domain/entities/armazenamento_grao.dart';
import 'database_helper.dart';

/// Responsável pelas operações de armazenamento de grãos.
class ArmazenamentoGraoRepository {
  /// Insere um novo registro de armazenamento.
  Future<int> inserir(ArmazenamentoGrao armazenamento) async {
    final db = await DatabaseHelper.database;

    return await db.insert('armazenamento_grao', armazenamento.toMap());
  }

  /// Lista os grãos armazenados da propriedade selecionada.
  Future<List<ArmazenamentoGrao>> listarPorPropriedade(
    int propriedadeId,
  ) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'armazenamento_grao',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'produto ASC',
    );

    return maps.map((map) => ArmazenamentoGrao.fromMap(map)).toList();
  }

  /// Busca um armazenamento específico pelo ID.
  Future<ArmazenamentoGrao?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'armazenamento_grao',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return ArmazenamentoGrao.fromMap(maps.first);
  }

  /// Atualiza os dados de um armazenamento existente.
  Future<int> atualizar(ArmazenamentoGrao armazenamento) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'armazenamento_grao',
      armazenamento.toMap(),
      where: 'id = ?',
      whereArgs: [armazenamento.id],
    );
  }
}
