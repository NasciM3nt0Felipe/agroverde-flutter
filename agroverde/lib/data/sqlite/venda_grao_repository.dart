import '../../domain/entities/venda_grao.dart';
import 'database_helper.dart';

/// Responsável pelas operações de venda de grãos.
class VendaGraoRepository {
  /// Registra uma nova venda.
  Future<int> inserir(VendaGrao venda) async {
    final db = await DatabaseHelper.database;

    return await db.insert('venda_grao', venda.toMap());
  }

  /// Grava a venda e baixa a quantidade disponível do armazenamento na
  /// mesma transação local. Revalida o saldo dentro da transação: se a
  /// quantidade for maior que a disponível, nada é gravado.
  Future<int> registrarVendaComBaixa(VendaGrao venda) async {
    final db = await DatabaseHelper.database;

    return await db.transaction((txn) async {
      final maps = await txn.query(
        'armazenamento_grao',
        where: 'id = ? AND propriedade_id = ?',
        whereArgs: [venda.armazenamentoId, venda.propriedadeId],
        limit: 1,
      );

      if (maps.isEmpty) {
        throw Exception('Armazenamento não encontrado.');
      }

      final disponivel = (maps.first['quantidade_disponivel'] as num)
          .toDouble();

      if (venda.quantidadeVendida > disponivel + 1e-9) {
        throw Exception('Quantidade vendida maior que a disponível.');
      }

      final restante = disponivel - venda.quantidadeVendida;
      final novaQuantidade = restante < 1e-9 ? 0.0 : restante;

      final vendaId = await txn.insert('venda_grao', venda.toMap());

      await txn.update(
        'armazenamento_grao',
        {
          'quantidade_disponivel': novaQuantidade,
          'status': novaQuantidade <= 0 ? 'Vendido' : 'Disponível',
        },
        where: 'id = ?',
        whereArgs: [venda.armazenamentoId],
      );

      return vendaId;
    });
  }

  /// Lista as vendas da propriedade.
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
