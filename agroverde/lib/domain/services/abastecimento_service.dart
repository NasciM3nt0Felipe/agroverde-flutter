import '../../data/sqlite/abastecimento_repository.dart';
import '../entities/abastecimento.dart';

/// Responsável pelas regras de negócio dos abastecimentos.
class AbastecimentoService {
  final AbastecimentoRepository _repository = AbastecimentoRepository();

  /// Salva ou atualiza um abastecimento.
  Future<int> salvar(Abastecimento abastecimento) async {
    if (abastecimento.id == null) {
      return await _repository.inserir(abastecimento);
    }

    return await _repository.atualizar(abastecimento);
  }

  /// Remove um abastecimento.
  Future<int> excluir(int id) async {
    return await _repository.excluir(id);
  }

  /// Busca um abastecimento pelo ID.
  Future<Abastecimento?> buscarPorId(int id) async {
    return await _repository.buscarPorId(id);
  }

  /// Lista os abastecimentos do veículo.
  Future<List<Abastecimento>> listarPorVeiculoId(int veiculoId) async {
    return await _repository.listarPorVeiculoId(veiculoId);
  }

  /// Calcula o total gasto com abastecimentos.
  Future<double> totalGastoVeiculo(int veiculoId) async {
    return await _repository.totalGastoVeiculo(veiculoId);
  }

  /// Calcula o total de litros abastecidos.
  Future<double> totalLitrosVeiculo(int veiculoId) async {
    return await _repository.totalLitrosVeiculo(veiculoId);
  }
}
