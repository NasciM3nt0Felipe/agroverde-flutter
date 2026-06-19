import '../../data/sqlite/safra_repository.dart';
import '../entities/safra.dart';

class SafraService {
  final SafraRepository _repository = SafraRepository();

  Future<List<Safra>> listarPorTalhaoId(int talhaoId) async {
    return await _repository.listarPorTalhaoId(talhaoId);
  }

  Future<void> salvar(Safra safra) async {
    if (safra.nome.trim().isEmpty) {
      throw Exception('Informe o nome da safra.');
    }

    if (safra.cultura.trim().isEmpty) {
      throw Exception('Informe a cultura.');
    }

    if (safra.dataPlantio.trim().isEmpty) {
      throw Exception('Informe a data de plantio.');
    }

    if (safra.status == 'Planejada' || safra.status == 'Em andamento') {
      final existeSafraAtiva = await _repository.existeSafraAtiva(
        safra.talhaoId,
        ignorarSafraId: safra.id,
      );

      if (existeSafraAtiva) {
        throw Exception('Já existe uma safra ativa neste talhão.');
      }
    }

    if (safra.id == null) {
      await _repository.inserir(safra);
    } else {
      await _repository.atualizar(safra);
    }
  }

  Future<void> excluir(int id) async {
    await _repository.excluir(id);
  }
}
