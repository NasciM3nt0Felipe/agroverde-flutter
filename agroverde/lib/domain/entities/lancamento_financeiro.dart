/// Origens de lançamentos automáticos (mesmos valores da API).
class OrigemLancamento {
  /// Gerado pela própria API (cadastro de estoque via API).
  static const String estoque = 'Estoque';

  /// Informados pelo app para módulos que ainda gravam localmente.
  static const String compraEstoque = 'CompraEstoque';
  static const String folhaPagamento = 'FolhaPagamento';
  static const String vendaGraos = 'VendaGraos';
  static const String abastecimento = 'Abastecimento';
  static const String manutencaoVeiculo = 'ManutencaoVeiculo';
  static const String vendaVeiculo = 'VendaVeiculo';

  /// Nome amigável para exibição.
  static String rotulo(String origem) {
    switch (origem) {
      case estoque:
      case compraEstoque:
        return 'Compra de estoque';
      case folhaPagamento:
        return 'Folha de pagamento';
      case vendaGraos:
        return 'Venda de grãos';
      case abastecimento:
        return 'Abastecimento';
      case manutencaoVeiculo:
        return 'Manutenção de veículo';
      case vendaVeiculo:
        return 'Venda de veículo';
      default:
        return origem;
    }
  }
}

class LancamentoFinanceiro {
  final int? id;
  final int propriedadeId;

  final String descricao;
  final double valor;
  final String tipo; // receita ou despesa
  final String data;
  final int? safraId;

  // Campos vindos da API. São opcionais para manter compatibilidade
  // com todos os pontos do app que já criam lançamentos.
  //
  // status: 'pago' (padrão), 'pendente' ou 'cancelado'.
  final String status;
  final String? categoria;
  final String? dataVencimento;
  final String? dataPagamento;

  /// Módulo que gerou o lançamento (null = lançamento manual).
  final String? origemTipo;

  /// Ações permitidas pela API para este lançamento.
  final bool permiteEditar;
  final bool permiteExcluir;

  LancamentoFinanceiro({
    this.id,
    required this.propriedadeId,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.data,
    this.safraId,
    this.status = 'pago',
    this.categoria,
    this.dataVencimento,
    this.dataPagamento,
    this.origemTipo,
    this.permiteEditar = true,
    this.permiteExcluir = true,
  });

  /// Indica se o lançamento já foi efetivado.
  ///
  /// Apenas lançamentos pagos compõem o saldo disponível:
  /// receitas pendentes não aumentam e despesas pendentes não reduzem o saldo.
  bool get pago => status.toLowerCase() == 'pago';

  bool get pendente => status.toLowerCase() == 'pendente';

  bool get cancelado => status.toLowerCase() == 'cancelado';

  /// Lançamento gerado por outro módulo (folha, estoque, veículos...).
  bool get automatico => origemTipo != null && origemTipo!.isNotEmpty;

  // Mantém as mesmas colunas da tabela SQLite original.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propriedade_id': propriedadeId,
      'descricao': descricao,
      'valor': valor,
      'tipo': tipo,
      'data': data,
      'safra_id': safraId,
    };
  }

  factory LancamentoFinanceiro.fromMap(Map<String, dynamic> map) {
    return LancamentoFinanceiro(
      id: map['id'],
      propriedadeId: map['propriedade_id'],
      descricao: map['descricao'],
      valor: map['valor']?.toDouble() ?? 0.0,
      tipo: map['tipo'],
      data: map['data'],
      safraId: map['safra_id'],
      status: (map['status'] as String?) ?? 'pago',
    );
  }
}
