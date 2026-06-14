class EstoqueItem {
  final int? id;
  final int propriedadeId;
  final String nome;
  final String categoria;
  final double quantidadeInicial;
  final double quantidadeAtual;
  final String unidadeMedida;
  final double precoMedioUnitario;
  final double estoqueMinimo;
  final String? fornecedor;
  final String? observacao;

  EstoqueItem({
    this.id,
    required this.propriedadeId,
    required this.nome,
    required this.categoria,
    required this.quantidadeInicial,
    required this.quantidadeAtual,
    required this.unidadeMedida,
    required this.precoMedioUnitario,
    required this.estoqueMinimo,
    this.fornecedor,
    this.observacao,
  });

  double get valorTotal {
    return quantidadeAtual * precoMedioUnitario;
  }

  bool get estoqueZerado {
    return quantidadeAtual == 0;
  }

  bool get estoqueBaixo {
    return quantidadeAtual > 0 && quantidadeAtual <= estoqueMinimo;
  }

  EstoqueItem copyWith({
    int? id,
    int? propriedadeId,
    String? nome,
    String? categoria,
    double? quantidadeInicial,
    double? quantidadeAtual,
    String? unidadeMedida,
    double? precoMedioUnitario,
    double? estoqueMinimo,
    String? fornecedor,
    String? observacao,
  }) {
    return EstoqueItem(
      id: id ?? this.id,
      propriedadeId: propriedadeId ?? this.propriedadeId,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      quantidadeInicial: quantidadeInicial ?? this.quantidadeInicial,
      quantidadeAtual: quantidadeAtual ?? this.quantidadeAtual,
      unidadeMedida: unidadeMedida ?? this.unidadeMedida,
      precoMedioUnitario: precoMedioUnitario ?? this.precoMedioUnitario,
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      fornecedor: fornecedor ?? this.fornecedor,
      observacao: observacao ?? this.observacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propriedade_id': propriedadeId,
      'nome': nome,
      'categoria': categoria,
      'quantidade_inicial': quantidadeInicial,
      'quantidade_atual': quantidadeAtual,
      'unidade_medida': unidadeMedida,
      'preco_medio_unitario': precoMedioUnitario,
      'estoque_minimo': estoqueMinimo,
      'fornecedor': fornecedor,
      'observacao': observacao,
    };
  }

  factory EstoqueItem.fromMap(Map<String, dynamic> map) {
    return EstoqueItem(
      id: map['id'],
      propriedadeId: map['propriedade_id'],
      nome: map['nome'],
      categoria: map['categoria'],
      quantidadeInicial: map['quantidade_inicial']?.toDouble() ?? 0.0,
      quantidadeAtual: map['quantidade_atual']?.toDouble() ?? 0.0,
      unidadeMedida: map['unidade_medida'],
      precoMedioUnitario: map['preco_medio_unitario']?.toDouble() ?? 0.0,
      estoqueMinimo: map['estoque_minimo']?.toDouble() ?? 0.0,
      fornecedor: map['fornecedor'],
      observacao: map['observacao'],
    );
  }
}
