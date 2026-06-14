class SanitarioRebanho {
  final int? id;
  final int animalId;
  final String procedimento;
  final String data;
  final String? medicamento;
  final String? observacao;

  SanitarioRebanho({
    this.id,
    required this.animalId,
    required this.procedimento,
    required this.data,
    this.medicamento,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'animal_id': animalId,
      'procedimento': procedimento,
      'data': data,
      'medicamento': medicamento,
      'observacao': observacao,
    };
  }

  factory SanitarioRebanho.fromMap(Map<String, dynamic> map) {
    return SanitarioRebanho(
      id: map['id'],
      animalId: map['animal_id'],
      procedimento: map['procedimento'],
      data: map['data'],
      medicamento: map['medicamento'],
      observacao: map['observacao'],
    );
  }
}