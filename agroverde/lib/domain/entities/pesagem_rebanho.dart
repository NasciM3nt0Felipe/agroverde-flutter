class PesagemRebanho {
  final int? id;
  final int animalId;
  final double peso;
  final String data;
  final String? observacao;

  PesagemRebanho({
    this.id,
    required this.animalId,
    required this.peso,
    required this.data,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'peso': peso,
      'data': data,
      'observacao': observacao,
    };
  }

  factory PesagemRebanho.fromMap(Map<String, dynamic> map) {
    return PesagemRebanho(
      id: map['id'],
      animalId: map['animal_id'],
      peso: map['peso']?.toDouble() ?? 0.0,
      data: map['data'],
      observacao: map['observacao'],
    );
  }
}
