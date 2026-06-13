import '../../data/sqlite/estoque_repository.dart';
import '../entities/estoque_item.dart';

class EstoqueService {
  final EstoqueRepository _repository = EstoqueRepository();

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
    } else {
      await _repository.atualizar(item);
    }
  }

  Future<void> excluir(int id) async {
    await _repository.excluir(id);
  }
}
