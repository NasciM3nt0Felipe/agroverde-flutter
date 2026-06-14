class LancamentoFinanceiro {
  final int? id;
  final int propriedadeId;

  final String descricao;
  final double valor;
  final String tipo; // receita ou despesa
  final String data;
  final int? safraId;

  LancamentoFinanceiro({
    this.id,
    required this.propriedadeId,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.data,
    this.safraId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propriedade_id': propriedadeId,
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'data': data,
      'safra_id': safraId,
    };
  }

  factory LancamentoFinanceiro.fromMap(Map<String, dynamic> map) {
    return LancamentoFinanceiro(
      id: map['id'],
      propriedadeId: map['propriedade_id'],
      descricao: map['descricao'],
      valor: map['valor']?.toDouble() ?? 0.0,
      tipo: map['tipo'],
      data: map['data'],
      safraId: map['safra_id'],
    );
  }
}
