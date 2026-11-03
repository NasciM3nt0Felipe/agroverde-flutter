import '../../data/sqlite/vacinacao_repository.dart';
import '../entities/vacinacao_rebanho.dart';

class VacinacaoService {
  final VacinacaoRepository _vacinacaoRepository = VacinacaoRepository();

  /// Registra a vacinação na API, que valida o estoque da propriedade e
  /// baixa 1 dose na mesma transação do histórico (nada é gravado se a
  /// vacina não tiver saldo, e a mesma dose não é registrada duas vezes).
  Future<void> registrarVacinacao({
    required int propriedadeId,
    required VacinacaoRebanho vacinacao,
    int? estoqueItemId,
  }) async {
    if (vacinacao.vacina.trim().isEmpty) {
      throw Exception('Selecione uma vacina disponível no estoque.');
    }

    await _vacinacaoRepository.inserir(
      vacinacao,
      estoqueItemId: estoqueItemId,
    );
  }
}
