import '../../data/sqlite/abastecimento_repository.dart';
import '../entities/abastecimento.dart';

class AbastecimentoService {
  final AbastecimentoRepository _repository = AbastecimentoRepository();

  Future<int> salvar(Abastecimento abastecimento) async {
    if (abastecimento.id == null) {
      return await _repository.inserir(abastecimento);
    }

    return await _repository.atualizar(abastecimento);
  }

  Future<int> excluir(int id) async {
    return await _repository.excluir(id);
  }

  Future<Abastecimento?> buscarPorId(int id) async {
    return await _repository.buscarPorId(id);
  }

  Future<List<Abastecimento>> listarPorVeiculoId(int veiculoId) async {
    return await _repository.listarPorVeiculoId(veiculoId);
  }

  Future<double> totalGastoVeiculo(int veiculoId) async {
    return await _repository.totalGastoVeiculo(veiculoId);
  }

  Future<double> totalLitrosVeiculo(int veiculoId) async {
    return await _repository.totalLitrosVeiculo(veiculoId);
  }
}
