class ArmazenamentoGrao {
  final int? id;
  final int colheitaId;
  final int propriedadeId;
  final String produto;
  final double quantidadeTotal;
  final double quantidadeDisponivel;
  final String unidade;
  final String status;

  ArmazenamentoGrao({
    this.id,
    required this.colheitaId,
    required this.propriedadeId,
    required this.produto,
    required this.quantidadeTotal,
    required this.quantidadeDisponivel,
    required this.unidade,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'colheita_id': colheitaId,
      'propriedade_id': propriedadeId,
      'produto': produto,
      'quantidade_total': quantidadeTotal,
      'quantidade_disponivel': quantidadeDisponivel,
      'unidade': unidade,
      'status': status,
    };
  }

  factory ArmazenamentoGrao.fromMap(Map<String, dynamic> map) {
    return ArmazenamentoGrao(
      id: map['id'],
      colheitaId: map['colheita_id'],
      propriedadeId: map['propriedade_id'],
      produto: map['produto'],
      quantidadeTotal: (map['quantidade_total'] as num).toDouble(),
      quantidadeDisponivel: (map['quantidade_disponivel'] as num).toDouble(),
      unidade: map['unidade'],
      status: map['status'],
    );
  }
}
