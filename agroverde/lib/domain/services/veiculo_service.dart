import '../../data/sqlite/financeiro_repository.dart';
import '../../data/sqlite/veiculo_repository.dart';

import '../entities/lancamento_financeiro.dart';
import '../entities/veiculo.dart';

/// Responsável pelas regras de negócio dos veículos.
class VeiculoService {
  final VeiculoRepository _repository = VeiculoRepository();

  final FinanceiroRepository _financeiroRepository = FinanceiroRepository();

  /// Salva ou atualiza um veículo.
  Future<int> salvar(Veiculo veiculo) async {
    if (veiculo.nome.trim().isEmpty) {
      throw Exception('Informe o nome do veículo.');
    }

    final anoLimite = DateTime.now().year + 1;

    if (veiculo.ano != 0 && (veiculo.ano < 1950 || veiculo.ano > anoLimite)) {
      throw Exception('Ano inválido. Informe um ano entre 1950 e $anoLimite.');
    }

    if (veiculo.horimetroOdometroAtual < 0) {
      throw Exception('O horímetro/odômetro não pode ser negativo.');
    }

    if (veiculo.id == null) {
      return await _repository.inserir(veiculo);
    }

    return await _repository.atualizar(veiculo);
  }

  /// Remove um veículo.
  Future<int> excluir(int id) async {
    return await _repository.excluir(id);
  }

  /// Busca um veículo pelo ID.
  Future<Veiculo?> buscarPorId(int id) async {
    return await _repository.buscarPorId(id);
  }

  /// Lista os veículos da propriedade.
  Future<List<Veiculo>> listarPorPropriedade(int propriedadeId) async {
    return await _repository.listarPorPropriedadeId(propriedadeId);
  }

  /// Lista apenas veículos ativos.
  Future<List<Veiculo>> listarAtivos(int propriedadeId) async {
    return await _repository.listarAtivosPorPropriedadeId(propriedadeId);
  }

  /// Calcula o total obtido com vendas.
  Future<double> totalVendido(int propriedadeId) async {
    return await _repository.totalVendidoPorPropriedade(propriedadeId);
  }

  /// Retorna a quantidade de veículos cadastrados.
  Future<int> totalVeiculos(int propriedadeId) async {
    return await _repository.totalVeiculos(propriedadeId);
  }

  /// Mantido por compatibilidade: a despesa do abastecimento agora é
  /// criada pela API junto com o abastecimento (evita lançamento duplicado).
  Future<void> registrarAbastecimentoFinanceiro({
    required int propriedadeId,
    required String nomeVeiculo,
    required double valor,
    required String data,
  }) async {}

  /// Mantido por compatibilidade: a despesa da manutenção agora é criada
  /// pela API junto com a manutenção (evita lançamento duplicado).
  Future<void> registrarManutencaoFinanceira({
    required int propriedadeId,
    required String nomeVeiculo,
    required double valor,
    required String data,
  }) async {}

  /// Registra a venda do veículo no financeiro.
  Future<void> registrarVendaFinanceira({
    required int propriedadeId,
    required String nomeVeiculo,
    required double valor,
    required String data,
  }) async {
    final lancamento = LancamentoFinanceiro(
      propriedadeId: propriedadeId,
      descricao: 'Venda de veículo - $nomeVeiculo',
      valor: valor,
      tipo: 'receita',
      data: data,
      origemTipo: OrigemLancamento.vendaVeiculo,
    );

    await _financeiroRepository.inserir(lancamento);
  }
}
