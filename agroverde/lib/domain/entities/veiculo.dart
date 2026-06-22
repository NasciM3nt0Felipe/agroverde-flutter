class Veiculo {
  final int? id;
  final int propriedadeId;

  final String nome;
  final String tipo;

  final String marca;
  final String modelo;

  final int ano;

  final String placa;

  final double horimetroOdometroAtual;

  final String status;

  final double valorVenda;

  final String? dataVenda;

  final String observacao;

  Veiculo({
    this.id,
    required this.propriedadeId,
    required this.nome,
    required this.tipo,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.placa,
    required this.horimetroOdometroAtual,
    required this.status,
    required this.valorVenda,
    this.dataVenda,
    required this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propriedade_id': propriedadeId,
      'nome': nome,
      'tipo': tipo,
      'marca': marca,
      'modelo': modelo,
      'ano': ano,
      'placa': placa,
      'horimetro_odometro_atual': horimetroOdometroAtual,
      'status': status,
      'valor_venda': valorVenda,
      'data_venda': dataVenda,
      'observacao': observacao,
    };
  }

  factory Veiculo.fromMap(Map<String, dynamic> map) {
    return Veiculo(
      id: map['id'],
      propriedadeId: map['propriedade_id'],
      nome: map['nome'] ?? '',
      tipo: map['tipo'] ?? '',
      marca: map['marca'] ?? '',
      modelo: map['modelo'] ?? '',
      ano: map['ano'] ?? 0,
      placa: map['placa'] ?? '',
      horimetroOdometroAtual: (map['horimetro_odometro_atual'] ?? 0).toDouble(),
      status: map['status'] ?? 'Ativo',
      valorVenda: (map['valor_venda'] ?? 0).toDouble(),
      dataVenda: map['data_venda'],
      observacao: map['observacao'] ?? '',
    );
  }
}
