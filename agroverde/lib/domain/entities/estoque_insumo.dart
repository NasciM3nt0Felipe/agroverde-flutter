class EstoqueInsumo {
  final int? id;
  final int safraId;
  final int estoqueItemId;
  final double quantidadeUtilizada;
  final double valorTotal;
  final String dataMovimentacao;
  final String? observacao;

  EstoqueInsumo({
    this.id,
    required this.safraId,
    required this.estoqueItemId,
    required this.quantidadeUtilizada,
    required this.valorTotal,
    required this.dataMovimentacao,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'safra_id': safraId,
      'estoque_item_id': estoqueItemId,
      'quantidade_utilizada': quantidadeUtilizada,
      'valor_total': valorTotal,
      'data_movimentacao': dataMovimentacao,
      'observacao': observacao,
    };
  }

  factory EstoqueInsumo.fromMap(Map<String, dynamic> map) {
    return EstoqueInsumo(
      id: map['id'],
      safraId: map['safra_id'],
      estoqueItemId: map['estoque_item_id'],
      quantidadeUtilizada: map['quantidade_utilizada']?.toDouble() ?? 0.0,
      valorTotal: map['valor_total']?.toDouble() ?? 0.0,
      dataMovimentacao: map['data_movimentacao'],
      observacao: map['observacao'],
    );
  }
}
