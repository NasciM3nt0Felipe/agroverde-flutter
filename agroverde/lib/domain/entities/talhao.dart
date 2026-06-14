class Talhao {
  final int? id;
  final String nome;
  final double area;
  final String? descricao;

  Talhao({
    this.id,
    required this.nome,
    required this.area,
    this.descricao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'area': area,
      'descricao': descricao,
    };
  }

  factory Talhao.fromMap(Map<String, dynamic> map) {
    return Talhao(
      id: map['id'],
      nome: map['nome'],
      area: map['area'],
      descricao: map['descricao'],
    );
  }
}