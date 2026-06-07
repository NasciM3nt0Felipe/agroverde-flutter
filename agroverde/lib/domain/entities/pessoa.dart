class Pessoa {
  int? id;
  int usuarioId;
  String? nome;
  String? cpf;
  String? telefone;
  String? cep;
  String? rua;
  String? numero;
  String? bairro;
  String? cidade;
  String? estado;

  Pessoa({
    this.id,
    required this.usuarioId,
    this.nome,
    this.cpf,
    this.telefone,
    this.cep,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
    };
  }

  factory Pessoa.fromMap(Map<String, dynamic> map) {
    return Pessoa(
      id: map['id'],
      usuarioId: map['usuario_id'],
      nome: map['nome'],
      cpf: map['cpf'],
      telefone: map['telefone'],
      cep: map['cep'],
      rua: map['rua'],
      numero: map['numero'],
      bairro: map['bairro'],
      cidade: map['cidade'],
      estado: map['estado'],
    );
  }
}
