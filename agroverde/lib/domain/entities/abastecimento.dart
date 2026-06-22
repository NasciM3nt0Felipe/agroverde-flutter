class Abastecimento {
  final int? id;

  final int veiculoId;

  final String data;

  final double litros;

  final double valorTotal;

  final String observacao;

  Abastecimento({
    this.id,
    required this.veiculoId,
    required this.data,
    required this.litros,
    required this.valorTotal,
    required this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'veiculo_id': veiculoId,
      'data': data,
      'litros': litros,
      'valor_total': valorTotal,
      'observacao': observacao,
    };
  }

  factory Abastecimento.fromMap(Map<String, dynamic> map) {
    return Abastecimento(
      id: map['id'],
      veiculoId: map['veiculo_id'],

      data: map['data'] ?? '',

      litros: (map['litros'] ?? 0).toDouble(),

      valorTotal: (map['valor_total'] ?? 0).toDouble(),

      observacao: map['observacao'] ?? '',
    );
  }
}
