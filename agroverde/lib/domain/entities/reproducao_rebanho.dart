class ReproducaoRebanho {
  final int? id;
  final int animalId;
  final String tipo;
  final String data;
  final String? observacao;

  ReproducaoRebanho({
    this.id,
    required this.animalId,
    required this.tipo,
    required this.data,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'tipo': tipo,
      'data': data,
      'observacao': observacao,
    };
  }

  factory ReproducaoRebanho.fromMap(Map<String, dynamic> map) {
    return ReproducaoRebanho(
      id: map['id'],
      animalId: map['animal_id'],
      tipo: map['tipo'],
      data: map['data'],
      observacao: map['observacao'],
    );
  }
}