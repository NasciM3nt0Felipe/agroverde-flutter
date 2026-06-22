class Colheita {
  final int? id;
  final int safraId;
  final int propriedadeId;
  final String dataColheita;
  final double quantidadeProduzida;
  final String unidade;
  final String? observacao;

  Colheita({
    this.id,
    required this.safraId,
    required this.propriedadeId,
    required this.dataColheita,
    required this.quantidadeProduzida,
    required this.unidade,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'safra_id': safraId,
      'propriedade_id': propriedadeId,
      'data_colheita': dataColheita,
      'quantidade_produzida': quantidadeProduzida,
      'unidade': unidade,
      'observacao': observacao,
    };
  }

  factory Colheita.fromMap(Map<String, dynamic> map) {
    return Colheita(
      id: map['id'],
      safraId: map['safra_id'],
      propriedadeId: map['propriedade_id'],
      dataColheita: map['data_colheita'],
      quantidadeProduzida: (map['quantidade_produzida'] as num).toDouble(),
      unidade: map['unidade'],
      observacao: map['observacao'],
    );
  }
}
