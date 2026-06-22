import '../../data/sqlite/safra_repository.dart';
import '../entities/safra.dart';

/// Responsável pelas regras de negócio das safras.
class SafraService {
  final SafraRepository _repository = SafraRepository();

  /// Lista as safras do talhão.
  Future<List<Safra>> listarPorTalhaoId(int talhaoId) async {
    return await _repository.listarPorTalhaoId(talhaoId);
  }

  /// Salva ou atualiza uma safra.
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

    /// Garante apenas uma safra ativa por talhão.
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

  /// Remove uma safra.
  Future<void> excluir(int id) async {
    await _repository.excluir(id);
  }
}
