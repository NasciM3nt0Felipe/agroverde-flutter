import '../../data/sqlite/estoque_repository.dart';
import '../entities/estoque_item.dart';

/// Responsável pelas regras de negócio do estoque.
class EstoqueService {
  final EstoqueRepository _repository = EstoqueRepository();

  /// Lista os itens da propriedade.
  Future<List<EstoqueItem>> listarPorPropriedadeId(int propriedadeId) async {
    return await _repository.listarPorPropriedadeId(propriedadeId);
  }

  /// Filtra itens por categoria e descrição.
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

  /// Salva um item (a despesa da compra é registrada pela API).
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
      // A API cria o item e, se houver valor de compra, a despesa
      // (origem "Estoque") na mesma transação — o app não lança despesa.
      await _repository.inserir(item);
    } else {
      await _repository.atualizar(item);
    }
  }

  /// Remove um item do estoque.
  Future<void> excluir(int id) async {
    await _repository.excluir(id);
  }

  /// Baixa uma quantidade do estoque sem vínculo com safra.
  /// A API revalida o saldo.
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

    // A API faz a baixa e revalida o saldo.
    await _repository.consumir(
      estoqueItemId: estoqueItemId,
      quantidade: quantidade,
    );
  }

  /// Registra o consumo de insumos em uma safra.
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
      throw Exception(
        'Estoque insuficiente para ${item.nome}. '
        'Disponível: ${item.quantidadeAtual} ${item.unidadeMedida}.',
      );
    }

    // Baixa do saldo e registro do consumo em uma única transação na API,
    // que também valida a safra (mesma propriedade) e o saldo disponível.
    await _repository.registrarConsumoSafra(
      safraId: safraId,
      estoqueItemId: estoqueItemId,
      quantidade: quantidade,
      observacao: observacao,
    );
  }

  /// Verifica se a safra possui consumo registrado.
  Future<bool> existeConsumoPorSafra(int safraId) async {
    return await _repository.existeConsumoPorSafra(safraId);
  }

  /// Verifica consumo por categoria na safra.
  Future<bool> existeConsumoPorSafraECategoria({
    required int safraId,
    required String categoria,
  }) async {
    return await _repository.existeConsumoPorSafraECategoria(
      safraId: safraId,
      categoria: categoria,
    );
  }

  /// Busca o último consumo registrado da categoria.
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
