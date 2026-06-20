import '../../data/sqlite/estoque_repository.dart';
import '../entities/estoque_insumo.dart';
import '../../data/sqlite/financeiro_repository.dart';
import '../entities/estoque_item.dart';
import '../entities/lancamento_financeiro.dart';

class EstoqueService {
  final EstoqueRepository _repository = EstoqueRepository();
  final FinanceiroRepository _financeiroRepository = FinanceiroRepository();

  Future<List<EstoqueItem>> listarPorPropriedadeId(int propriedadeId) async {
    return await _repository.listarPorPropriedadeId(propriedadeId);
  }

  List<EstoqueItem> filtrarItens({
    required List<EstoqueItem> itens,
    required String categoria,
    required String busca,
  }) {
    final buscaTratada = busca.toLowerCase().trim();

    return itens.where((item) {
      final categoriaConfere =
          categoria == 'Todos' || item.categoria == categoria;

      final nomeConfere =
          buscaTratada.isEmpty ||
          item.nome.toLowerCase().contains(buscaTratada);

      return categoriaConfere && nomeConfere;
    }).toList();
  }

  Future<void> salvar(EstoqueItem item) async {
    if (item.nome.trim().isEmpty) {
      throw Exception('Informe o nome do item.');
    }

    if (item.categoria.trim().isEmpty) {
      throw Exception('Informe a categoria.');
    }

    if (item.quantidadeInicial < 0) {
      throw Exception('A quantidade inicial não pode ser negativa.');
    }

    if (item.quantidadeAtual < 0) {
      throw Exception('A quantidade atual não pode ser negativa.');
    }

    if (item.precoMedioUnitario < 0) {
      throw Exception('O preço médio não pode ser negativo.');
    }

    if (item.estoqueMinimo < 0) {
      throw Exception('O estoque mínimo não pode ser negativo.');
    }

    if (item.id == null) {
      await _repository.inserir(item);

      final valorTotal = item.quantidadeInicial * item.precoMedioUnitario;

      if (valorTotal > 0) {
        await _financeiroRepository.inserir(
          LancamentoFinanceiro(
            propriedadeId: item.propriedadeId,
            descricao: 'Compra de ${item.nome}',
            valor: valorTotal,
            tipo: 'despesa',
            data: DateTime.now().toIso8601String(),
            safraId: null,
          ),
        );
      }
    } else {
      await _repository.atualizar(item);
    }
  }

  Future<void> excluir(int id) async {
    await _repository.excluir(id);
  }

  /// Consome uma quantidade do estoque.
  ///
  /// Utilizado por:
  /// - Plantio
  /// - Fertilização
  /// - Pulverização
  /// - Vacinação
  ///
  /// Valida saldo antes de realizar a baixa.
  Future<void> consumirEstoque({
    required int estoqueItemId,
    required double quantidade,
  }) async {
    if (quantidade <= 0) {
      throw Exception('A quantidade consumida deve ser maior que zero.');
    }

    final item = await _repository.buscarPorId(estoqueItemId);

    if (item == null) {
      throw Exception('Item de estoque não encontrado.');
    }

    if (item.quantidadeAtual < quantidade) {
      throw Exception(
        'Estoque insuficiente para ${item.nome}. '
        'Disponível: ${item.quantidadeAtual} ${item.unidadeMedida}.',
      );
    }

    final itemAtualizado = EstoqueItem(
      id: item.id,
      propriedadeId: item.propriedadeId,
      nome: item.nome,
      categoria: item.categoria,
      quantidadeInicial: item.quantidadeInicial,
      quantidadeAtual: item.quantidadeAtual - quantidade,
      unidadeMedida: item.unidadeMedida,
      precoMedioUnitario: item.precoMedioUnitario,
      estoqueMinimo: item.estoqueMinimo,
      fornecedor: item.fornecedor,
      observacao: item.observacao,
    );

    await _repository.atualizar(itemAtualizado);
  }

  /// Registra o consumo de um insumo em uma safra.
  ///
  /// Utilizado por:
  /// - Plantio
  /// - Fertilização
  /// - Pulverização
  Future<void> registrarConsumoSafra({
    required int safraId,
    required int estoqueItemId,
    required double quantidade,
    String? observacao,
  }) async {
    if (quantidade <= 0) {
      throw Exception('A quantidade utilizada deve ser maior que zero.');
    }

    final item = await _repository.buscarPorId(estoqueItemId);

    if (item == null) {
      throw Exception('Item de estoque não encontrado.');
    }

    if (item.quantidadeAtual < quantidade) {
      throw Exception('Estoque insuficiente para ${item.nome}.');
    }

    await consumirEstoque(estoqueItemId: estoqueItemId, quantidade: quantidade);

    final valorTotal = quantidade * item.precoMedioUnitario;

    final consumo = EstoqueInsumo(
      safraId: safraId,
      estoqueItemId: estoqueItemId,
      quantidadeUtilizada: quantidade,
      valorTotal: valorTotal,
      dataMovimentacao: DateTime.now().toIso8601String(),
      observacao: observacao,
    );

    await _repository.inserirConsumoInsumo(consumo);
  }

  Future<bool> existeConsumoPorSafra(int safraId) async {
    return await _repository.existeConsumoPorSafra(safraId);
  }

  Future<bool> existeConsumoPorSafraECategoria({
    required int safraId,
    required String categoria,
  }) async {
    return await _repository.existeConsumoPorSafraECategoria(
      safraId: safraId,
      categoria: categoria,
    );
  }

  Future<Map<String, dynamic>?> buscarUltimoConsumoPorCategoria({
    required int safraId,
    required String categoria,
  }) async {
    return await _repository.buscarUltimoConsumoPorCategoria(
      safraId: safraId,
      categoria: categoria,
    );
  }
}
