import '../../data/sqlite/estoque_repository.dart';
import '../../data/sqlite/vacinacao_repository.dart';
import '../entities/vacinacao_rebanho.dart';

class VacinacaoService {
  final VacinacaoRepository _vacinacaoRepository = VacinacaoRepository();
  final EstoqueRepository _estoqueRepository = EstoqueRepository();

  Future<void> registrarVacinacao({
    required int propriedadeId,
    required VacinacaoRebanho vacinacao,
  }) async {
    final vacinaEstoque = await _estoqueRepository
        .buscarPorNomeCategoriaEPropriedade(
          propriedadeId: propriedadeId,
          nome: vacinacao.vacina,
          categoria: 'Vacinas',
        );

    if (vacinaEstoque == null) {
      throw Exception('Vacina não cadastrada no estoque desta propriedade.');
    }

    if (vacinaEstoque.quantidadeAtual <= 0) {
      throw Exception('Não há estoque disponível para esta vacina.');
    }

    final itemAtualizado = vacinaEstoque.copyWith(
      quantidadeAtual: vacinaEstoque.quantidadeAtual - 1,
    );

    await _estoqueRepository.atualizar(itemAtualizado);
    await _vacinacaoRepository.inserir(vacinacao);
  }
}
