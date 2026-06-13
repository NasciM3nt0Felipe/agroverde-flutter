import '../../domain/entities/talhao.dart';
import 'database_helper.dart';

/// Repository responsável pelas operações da entidade Talhão.
///
/// Aqui centralizamos toda comunicação com o SQLite,
/// evitando que a tela acesse o banco diretamente.
class TalhaoRepository {
  /// Insere um novo talhão no banco.
  ///
  /// Retorna o ID gerado pelo SQLite.
  Future<int> inserir(Talhao talhao) async {
    final db = await DatabaseHelper.database;

    return await db.insert('talhao', talhao.toMap());
  }

  /// Lista todos os talhões vinculados
  /// à propriedade informada.
  ///
  /// Utilizado para exibir apenas os talhões
  /// da propriedade atualmente em foco.
  Future<List<Talhao>> listarPorPropriedadeId(int propriedadeId) async {
    final db = await DatabaseHelper.database;

    final maps = await db.query(
      'talhao',

      /// Filtra apenas os talhões da propriedade.
      where: 'propriedade_id = ?',

      /// Valor utilizado no filtro acima.
      whereArgs: [propriedadeId],

      /// Ordenação alfabética pelo nome.
      orderBy: 'nome ASC',
    );

    return maps.map((map) => Talhao.fromMap(map)).toList();
  }

  /// Atualiza um talhão já existente.
  ///
  /// O registro é localizado através do ID.
  Future<int> atualizar(Talhao talhao) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'talhao',

      /// Novos valores.
      talhao.toMap(),

      /// Localiza o registro.
      where: 'id = ?',

      /// Valor utilizado no filtro.
      whereArgs: [talhao.id],
    );
  }

  /// Remove um talhão do banco.
  ///
  /// Recebe o ID do talhão que será excluído.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete(
      'talhao',

      /// Localiza o registro.
      where: 'id = ?',

      /// Valor utilizado no filtro.
      whereArgs: [id],
    );
  }
}
