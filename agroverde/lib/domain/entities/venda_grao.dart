class VendaGrao {
  final int? id;
  final int armazenamentoId;
  final int propriedadeId;
  final String dataVenda;
  final String? comprador;
  final double quantidadeVendida;
  final double valorUnitario;
  final double valorTotal;
  final String unidade;
  final String? observacao;

  VendaGrao({
    this.id,
    required this.armazenamentoId,
    required this.propriedadeId,
    required this.dataVenda,
    this.comprador,
    required this.quantidadeVendida,
    required this.valorUnitario,
    required this.valorTotal,
    required this.unidade,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'armazenamento_id': armazenamentoId,
      'propriedade_id': propriedadeId,
      'data_venda': dataVenda,
      'comprador': comprador,
      'quantidade_vendida': quantidadeVendida,
      'valor_unitario': valorUnitario,
      'valor_total': valorTotal,
      'unidade': unidade,
      'observacao': observacao,
    };
  }

  factory VendaGrao.fromMap(Map<String, dynamic> map) {
    return VendaGrao(
      id: map['id'],
      armazenamentoId: map['armazenamento_id'],
      propriedadeId: map['propriedade_id'],
      dataVenda: map['data_venda'],
      comprador: map['comprador'],
      quantidadeVendida: (map['quantidade_vendida'] as num).toDouble(),
      valorUnitario: (map['valor_unitario'] as num).toDouble(),
      valorTotal: (map['valor_total'] as num).toDouble(),
      unidade: map['unidade'],
      observacao: map['observacao'],
    );
  }
}
