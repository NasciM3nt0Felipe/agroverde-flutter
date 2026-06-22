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
      where: 'talhao_id = ?',
      whereArgs: [talhaoId],
      orderBy: 'id DESC',
    );

    return maps.map((map) => Safra.fromMap(map)).toList();
  }

  /// Lista as safras que já podem ser colhidas.
  ///
  /// Critérios:
  /// - possuem data de colheita prevista menor ou igual à data atual;
  /// - ainda não estão com status Colhida ou Finalizada.
  Future<List<Safra>> listarDisponiveisParaColheitaPorPropriedade(
    int propriedadeId,
  ) async {
    final db = await DatabaseHelper.database;

    final hoje = DateTime.now().toIso8601String().substring(0, 10);

    final maps = await db.rawQuery(
      '''
    SELECT s.*
    FROM safra s
    INNER JOIN talhao t ON t.id = s.talhao_id
    WHERE t.propriedade_id = ?
      AND s.data_colheita_prevista IS NOT NULL
      AND s.data_colheita_prevista != ''
      AND (
        substr(s.data_colheita_prevista, 7, 4) || '-' ||
        substr(s.data_colheita_prevista, 4, 2) || '-' ||
        substr(s.data_colheita_prevista, 1, 2)
      ) <= ?
      AND s.status NOT IN (?, ?)
    ORDER BY (
      substr(s.data_colheita_prevista, 7, 4) || '-' ||
      substr(s.data_colheita_prevista, 4, 2) || '-' ||
      substr(s.data_colheita_prevista, 1, 2)
    ) ASC
    ''',
      [propriedadeId, hoje, 'Colhida', 'Finalizada'],
    );

    return maps.map((map) => Safra.fromMap(map)).toList();
  }

  /// Verifica se já existe uma safra ativa no talhão.
  ///
  /// Status considerados ativos:
  /// - Planejada
  /// - Em andamento
  ///
  /// O parâmetro ignorarSafraId é usado na edição,
  /// para não comparar a safra com ela mesma.
  Future<bool> existeSafraAtiva(int talhaoId, {int? ignorarSafraId}) async {
    final db = await DatabaseHelper.database;

    String where = 'talhao_id = ? AND status IN (?, ?)';

    final whereArgs = <dynamic>[talhaoId, 'Planejada', 'Em andamento'];

    if (ignorarSafraId != null) {
      where += ' AND id != ?';
      whereArgs.add(ignorarSafraId);
    }

    final maps = await db.query(
      'safra',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
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

  Future<Safra?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'safra',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Safra.fromMap(maps.first);
  }
}
