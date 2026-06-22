class ManutencaoVeiculo {
  final int? id;

  final int veiculoId;

  final String data;

  final String tipo;

  final String descricao;

  final double valor;

  final String observacao;

  ManutencaoVeiculo({
    this.id,
    required this.veiculoId,
    required this.data,
    required this.tipo,
    required this.descricao,
    required this.valor,
    required this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'veiculo_id': veiculoId,
      'data': data,
      'tipo': tipo,
      'descricao': descricao,
      'valor': valor,
      'observacao': observacao,
    };
  }

  factory ManutencaoVeiculo.fromMap(Map<String, dynamic> map) {
    return ManutencaoVeiculo(
      id: map['id'],
      veiculoId: map['veiculo_id'],
      data: map['data'] ?? '',
      tipo: map['tipo'] ?? '',
      descricao: map['descricao'] ?? '',
      valor: (map['valor'] ?? 0).toDouble(),
      observacao: map['observacao'] ?? '',
    );
  }
}
