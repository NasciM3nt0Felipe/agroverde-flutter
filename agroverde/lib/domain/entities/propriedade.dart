class Propriedade {
  int? id;
  int usuarioId;
  String nome;
  double areaTotal;
  String? cidade;
  String? estado;
  String? descricao;

  Propriedade({
    this.id,
    required this.usuarioId,
    required this.nome,
    required this.areaTotal,
    this.cidade,
    this.estado,
    this.descricao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'nome': nome,
      'area_total': areaTotal,
      'cidade': cidade,
      'estado': estado,
      'descricao': descricao,
    };
  }

  factory Propriedade.fromMap(Map<String, dynamic> map) {
    return Propriedade(
      id: map['id'],
      usuarioId: map['usuario_id'],
      nome: map['nome'],
      areaTotal: map['area_total'],
      cidade: map['cidade'],
      estado: map['estado'],
      descricao: map['descricao'],
    );
  }
}
