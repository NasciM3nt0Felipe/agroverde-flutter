class Funcionario {
  int? id;
  int pessoaId;
  int propriedadeId;
  String cargo;
  double? salario;
  String? dataContratacao;
  String? dataDesligamento;
  String status;
  String? observacao;

  Funcionario({
    this.id,
    required this.pessoaId,
    required this.propriedadeId,
    required this.cargo,
    this.salario,
    this.dataContratacao,
    this.dataDesligamento,
    required this.status,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pessoa_id': pessoaId,
      'propriedade_id': propriedadeId,
      'cargo': cargo,
      'salario': salario,
      'data_contratacao': dataContratacao,
      'data_desligamento': dataDesligamento,
      'status': status,
      'observacao': observacao,
    };
  }

  factory Funcionario.fromMap(Map<String, dynamic> map) {
    return Funcionario(
      id: map['id'],
      pessoaId: map['pessoa_id'],
      propriedadeId: map['propriedade_id'],
      cargo: map['cargo'] ?? '',
      salario: map['salario'] != null
          ? (map['salario'] as num).toDouble()
          : null,
      dataContratacao: map['data_contratacao'],
      dataDesligamento: map['data_desligamento'],
      status: map['status'] ?? 'Ativo',
      observacao: map['observacao'],
    );
  }

  bool get ativo => status == 'Ativo';

  bool get desligado => status == 'Desligado';
}
