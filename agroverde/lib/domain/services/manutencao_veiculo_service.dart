import '../../data/sqlite/manutencao_veiculo_repository.dart';
import '../entities/manutencao_veiculo.dart';

/// Responsável pelas regras de negócio das manutenções.
class ManutencaoVeiculoService {
  final ManutencaoVeiculoRepository _repository = ManutencaoVeiculoRepository();

  /// Salva ou atualiza uma manutenção.
  Future<int> salvar(ManutencaoVeiculo manutencao) async {
    if (manutencao.id == null) {
      return await _repository.inserir(manutencao);
    }

    return await _repository.atualizar(manutencao);
  }

  /// Remove uma manutenção.
  Future<int> excluir(int id) async {
    return await _repository.excluir(id);
  }

  /// Busca uma manutenção pelo ID.
  Future<ManutencaoVeiculo?> buscarPorId(int id) async {
    return await _repository.buscarPorId(id);
  }

  /// Lista as manutenções do veículo.
  Future<List<ManutencaoVeiculo>> listarPorVeiculoId(int veiculoId) async {
    return await _repository.listarPorVeiculoId(veiculoId);
  }

  /// Calcula o total gasto com manutenção.
  Future<double> totalGastoVeiculo(int veiculoId) async {
    return await _repository.totalGastoVeiculo(veiculoId);
  }

  /// Retorna a quantidade de manutenções registradas.
  Future<int> quantidadeManutencoes(int veiculoId) async {
    return await _repository.quantidadeManutencoes(veiculoId);
  }
}
