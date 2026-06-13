import '../../domain/entities/safra.dart';
import 'database_helper.dart';

/// Repository responsável pelas operações da entidade Safra.
///
/// A Safra representa um ciclo produtivo dentro de um Talhão.
///
/// Fluxo:
/// Propriedade -> Talhão -> Safra
class SafraRepository {
  /// Insere uma nova safra no banco.
  ///
  /// Retorna o ID gerado pelo SQLite.
  Future<int> inserir(Safra safra) async {
    final db = await DatabaseHelper.database;

    return await db.insert('safra', safra.toMap());
  }

  /// Lista todas as safras vinculadas a um talhão específico.
  ///
  /// Usado para mostrar somente as safras do talhão selecionado.
  Future<List<Safra>> listarPorTalhaoId(int talhaoId) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'safra',

      /// Filtra as safras pelo talhão.
      where: 'talhao_id = ?',

      /// ID do talhão selecionado.
      whereArgs: [talhaoId],

      /// Mostra as mais recentes primeiro.
      orderBy: 'id DESC',
    );

    return maps.map((map) => Safra.fromMap(map)).toList();
  }

  /// Atualiza os dados de uma safra existente.
  ///
  /// A safra é localizada pelo seu ID.
  Future<int> atualizar(Safra safra) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'safra',
      safra.toMap(),
      where: 'id = ?',
      whereArgs: [safra.id],
    );
  }

  /// Exclui uma safra do banco.
  ///
  /// Recebe o ID da safra que será removida.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('safra', where: 'id = ?', whereArgs: [id]);
  }
}
