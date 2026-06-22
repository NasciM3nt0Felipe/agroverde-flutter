import '../../domain/entities/estoque_item.dart';
import '../../domain/entities/estoque_insumo.dart';
import 'database_helper.dart';

/// Responsável pelas operações de estoque e consumo de insumos.
class EstoqueRepository {
  /// Insere um novo item de estoque.
  Future<int> inserir(EstoqueItem item) async {
    final db = await DatabaseHelper.database;

    return await db.insert('estoque_item', item.toMap());
  }

  /// Registra o consumo de insumos da safra.
  Future<int> inserirConsumoInsumo(EstoqueInsumo consumo) async {
    final db = await DatabaseHelper.database;

    return await db.insert('estoque_insumo', consumo.toMap());
  }

  /// Lista os itens de estoque da propriedade.
  Future<List<EstoqueItem>> listarPorPropriedadeId(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'estoque_item',
      where: 'propriedade_id = ?',
      whereArgs: [propriedadeId],
      orderBy: 'nome ASC',
    );

    return maps.map((map) {
      return EstoqueItem.fromMap(map);
    }).toList();
  }

  /// Lista as vacinas disponíveis em estoque.
  Future<List<EstoqueItem>> listarVacinasDisponiveisPorPropriedade(
    int propriedadeId,
  ) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'estoque_item',
      where:
          'propriedade_id = ? AND LOWER(categoria) = ? AND quantidade_atual > 0',
      whereArgs: [propriedadeId, 'vacinas'],
      orderBy: 'nome ASC',
    );

    return maps.map((map) {
      return EstoqueItem.fromMap(map);
    }).toList();
  }

  /// Busca item por nome, categoria e propriedade.
  Future<EstoqueItem?> buscarPorNomeCategoriaEPropriedade({
    required int propriedadeId,
    required String nome,
    required String categoria,
  }) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'estoque_item',
      where: 'propriedade_id = ? AND LOWER(nome) = ? AND LOWER(categoria) = ?',
      whereArgs: [
        propriedadeId,
        nome.trim().toLowerCase(),
        categoria.trim().toLowerCase(),
      ],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return EstoqueItem.fromMap(maps.first);
  }

  /// Busca um item específico pelo ID.
  Future<EstoqueItem?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'estoque_item',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return EstoqueItem.fromMap(maps.first);
  }

  /// Atualiza os dados de um item.
  Future<int> atualizar(EstoqueItem item) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'estoque_item',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Verifica se a safra já possui algum consumo registrado.
  ///
  /// Usado no card da safra para indicar visualmente
  /// se já existe plantio/consumo de insumos vinculado.
  Future<bool> existeConsumoPorSafra(int safraId) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'estoque_insumo',
      where: 'safra_id = ?',
      whereArgs: [safraId],
      limit: 1,
    );

    return resultado.isNotEmpty;
  }

  /// Remove um item do estoque.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('estoque_item', where: 'id = ?', whereArgs: [id]);
  }

  /// Verifica se existe consumo de insumo por safra e categoria.
  ///
  /// Exemplo:
  /// - Sementes -> Plantio
  /// - Fertilizantes -> Fertilização
  /// - Defensivos -> Pulverização
  Future<bool> existeConsumoPorSafraECategoria({
    required int safraId,
    required String categoria,
  }) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.rawQuery(
      '''
    SELECT ei.id
    FROM estoque_insumo ei
    INNER JOIN estoque_item item
      ON item.id = ei.estoque_item_id
    WHERE ei.safra_id = ?
      AND LOWER(item.categoria) = ?
    LIMIT 1
    ''',
      [safraId, categoria.trim().toLowerCase()],
    );

    return resultado.isNotEmpty;
  }

  /// Busca o último consumo de uma safra por categoria de estoque.
  ///
  /// Usado para montar o resumo operacional da safra com:
  /// item utilizado, quantidade, unidade e data.
  Future<Map<String, dynamic>?> buscarUltimoConsumoPorCategoria({
    required int safraId,
    required String categoria,
  }) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.rawQuery(
      '''
      SELECT
        item.nome AS nome,
        item.unidade_medida AS unidade_medida,
        ei.quantidade_utilizada AS quantidade_utilizada,
        ei.data_movimentacao AS data_movimentacao
      FROM estoque_insumo ei
      INNER JOIN estoque_item item
        ON item.id = ei.estoque_item_id
      WHERE ei.safra_id = ?
        AND LOWER(item.categoria) = ?
      ORDER BY ei.id DESC
      LIMIT 1
      ''',
      [safraId, categoria.trim().toLowerCase()],
    );

    if (resultado.isEmpty) {
      return null;
    }

    return resultado.first;
  }
}
