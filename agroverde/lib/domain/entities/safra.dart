class Safra {
  final int? id;
  final int talhaoId;
  final String nome;
  final String cultura;
  final String? variedade;
  final String dataPlantio;
  final String? dataColheitaPrevista;
  final String? dataColheitaReal;
  final double? producaoEstimada;
  final double? producaoObtida;
  final String status;
  final String? observacao;

  Safra({
    this.id,
    required this.talhaoId,
    required this.nome,
    required this.cultura,
    this.variedade,
    required this.dataPlantio,
    this.dataColheitaPrevista,
    this.dataColheitaReal,
    this.producaoEstimada,
    this.producaoObtida,
    this.status = 'Planejada',
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'talhao_id': talhaoId,
      'nome': nome,
      'cultura': cultura,
      'variedade': variedade,
      'data_plantio': dataPlantio,
      'data_colheita_prevista': dataColheitaPrevista,
      'data_colheita_real': dataColheitaReal,
      'producao_estimada': producaoEstimada,
      'producao_obtida': producaoObtida,
      'status': status,
      'observacao': observacao,
    };
  }

  factory Safra.fromMap(Map<String, dynamic> map) {
    return Safra(
      id: map['id'],
      talhaoId: map['talhao_id'],
      nome: map['nome'],
      cultura: map['cultura'],
      variedade: map['variedade'],
      dataPlantio: map['data_plantio'],
      dataColheitaPrevista: map['data_colheita_prevista'],
      dataColheitaReal: map['data_colheita_real'],
      producaoEstimada: map['producao_estimada'],
      producaoObtida: map['producao_obtida'],
      status: map['status'],
      observacao: map['observacao'],
    );
  }
}
