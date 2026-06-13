class Talhao {
  final int? id;
  final int propriedadeId;
  final String nome;
  final double area;
  final String? tipoSolo;
  final String? observacao;
  final bool ativo;

  Talhao({
    this.id,
    required this.propriedadeId,
    required this.nome,
    required this.area,
    this.tipoSolo,
    this.observacao,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propriedade_id': propriedadeId,
      'nome': nome,
      'area': area,
      'tipo_solo': tipoSolo,
      'observacao': observacao,
      'ativo': ativo ? 1 : 0,
    };
  }

  factory Talhao.fromMap(Map<String, dynamic> map) {
    return Talhao(
      id: map['id'],
      propriedadeId: map['propriedade_id'],
      nome: map['nome'],
      area: map['area'],
      tipoSolo: map['tipo_solo'],
      observacao: map['observacao'],
      ativo: map['ativo'] == 1,
    );
  }
}
