class Safra {
  final int? id;
  final String nome;
  final String cultura;
  final int ano;
  final int? talhaoId;

  Safra({
    this.id,
    required this.nome,
    required this.cultura,
    required this.ano,
    this.talhaoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cultura': cultura,
      'ano': ano,
      'talhao_id': talhaoId,
    };
  }

  factory Safra.fromMap(Map<String, dynamic> map) {
    return Safra(
      id: map['id'],
      nome: map['nome'],
      cultura: map['cultura'],
      ano: map['ano'],
      talhaoId: map['talhao_id'],
    );
  }
}