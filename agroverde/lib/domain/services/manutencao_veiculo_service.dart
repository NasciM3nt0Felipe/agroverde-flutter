import '../../data/sqlite/manutencao_veiculo_repository.dart';
import '../entities/manutencao_veiculo.dart';

class ManutencaoVeiculoService {
  final ManutencaoVeiculoRepository _repository = ManutencaoVeiculoRepository();

  Future<int> salvar(ManutencaoVeiculo manutencao) async {
    if (manutencao.id == null) {
      return await _repository.inserir(manutencao);
    }

    return await _repository.atualizar(manutencao);
  }

  Future<int> excluir(int id) async {
    return await _repository.excluir(id);
  }

  Future<ManutencaoVeiculo?> buscarPorId(int id) async {
    return await _repository.buscarPorId(id);
  }

  Future<List<ManutencaoVeiculo>> listarPorVeiculoId(int veiculoId) async {
    return await _repository.listarPorVeiculoId(veiculoId);
  }

  Future<double> totalGastoVeiculo(int veiculoId) async {
    return await _repository.totalGastoVeiculo(veiculoId);
  }

  Future<int> quantidadeManutencoes(int veiculoId) async {
    return await _repository.quantidadeManutencoes(veiculoId);
  }
}
