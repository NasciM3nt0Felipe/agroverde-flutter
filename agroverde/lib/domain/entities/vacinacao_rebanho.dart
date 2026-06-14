class VacinacaoRebanho {
  final int? id;
  final int animalId;
  final String vacina;
  final String dataAplicacao;
  final String? proximaDose;
  final String? observacao;

  VacinacaoRebanho({
    this.id,
    required this.animalId,
    required this.vacina,
    required this.dataAplicacao,
    this.proximaDose,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'vacina': vacina,
      'data_aplicacao': dataAplicacao,
      'proxima_dose': proximaDose,
      'observacao': observacao,
    };
  }

  factory VacinacaoRebanho.fromMap(Map<String, dynamic> map) {
    return VacinacaoRebanho(
      id: map['id'],
      animalId: map['animal_id'],
      vacina: map['vacina'],
      dataAplicacao: map['data_aplicacao'],
      proximaDose: map['proxima_dose'],
      observacao: map['observacao'],
    );
  }
}