import '../../data/sqlite/financeiro_repository.dart';
import '../../data/sqlite/veiculo_repository.dart';

import '../entities/lancamento_financeiro.dart';
import '../entities/veiculo.dart';

class VeiculoService {
  final VeiculoRepository _repository = VeiculoRepository();

  final FinanceiroRepository _financeiroRepository = FinanceiroRepository();

  Future<int> salvar(Veiculo veiculo) async {
    if (veiculo.id == null) {
      return await _repository.inserir(veiculo);
    }

    return await _repository.atualizar(veiculo);
  }

  Future<int> excluir(int id) async {
    return await _repository.excluir(id);
  }

  Future<Veiculo?> buscarPorId(int id) async {
    return await _repository.buscarPorId(id);
  }

  Future<List<Veiculo>> listarPorPropriedade(int propriedadeId) async {
    return await _repository.listarPorPropriedadeId(propriedadeId);
  }

  Future<List<Veiculo>> listarAtivos(int propriedadeId) async {
    return await _repository.listarAtivosPorPropriedadeId(propriedadeId);
  }

  Future<double> totalVendido(int propriedadeId) async {
    return await _repository.totalVendidoPorPropriedade(propriedadeId);
  }

  Future<int> totalVeiculos(int propriedadeId) async {
    return await _repository.totalVeiculos(propriedadeId);
  }

  // ==========================
  // FINANCEIRO
  // ==========================

  Future<void> registrarAbastecimentoFinanceiro({
    required int propriedadeId,
    required String nomeVeiculo,
    required double valor,
    required String data,
  }) async {
    final lancamento = LancamentoFinanceiro(
      propriedadeId: propriedadeId,
      descricao: 'Abastecimento - $nomeVeiculo',
      valor: valor,
      tipo: 'despesa',
      data: data,
    );

    await _financeiroRepository.inserir(lancamento);
  }

  Future<void> registrarManutencaoFinanceira({
    required int propriedadeId,
    required String nomeVeiculo,
    required double valor,
    required String data,
  }) async {
    final lancamento = LancamentoFinanceiro(
      propriedadeId: propriedadeId,
      descricao: 'Manutenção - $nomeVeiculo',
      valor: valor,
      tipo: 'despesa',
      data: data,
    );

    await _financeiroRepository.inserir(lancamento);
  }

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
    );

    await _financeiroRepository.inserir(lancamento);
  }
}
