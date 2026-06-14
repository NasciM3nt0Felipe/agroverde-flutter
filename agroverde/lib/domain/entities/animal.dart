class Animal {
  final int? id;
  final String identificacao;
  final String especie;
  final String? raca;
  final String sexo;
  final String? dataNascimento;
  final double? peso;
  final String status;
  final String? observacao;

  Animal({
    this.id,
    required this.identificacao,
    required this.especie,
    this.raca,
    required this.sexo,
    this.dataNascimento,
    this.peso,
    required this.status,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'identificacao': identificacao,
      'especie': especie,
      'raca': raca,
      'sexo': sexo,
      'data_nascimento': dataNascimento,
      'peso': peso,
      'status': status,
      'observacao': observacao,
    };
  }

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'],
      identificacao: map['identificacao'],
      especie: map['especie'],
      raca: map['raca'],
      sexo: map['sexo'],
      dataNascimento: map['data_nascimento'],
      peso: map['peso'],
      status: map['status'],
      observacao: map['observacao'],
    );
  }
}