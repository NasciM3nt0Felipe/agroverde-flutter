import '../../domain/entities/estoque_item.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/api_json.dart';

/// Responsável pelas operações de estoque e consumo de insumos — via API
/// (/api/Estoque).
///
/// O usuário vem do token JWT e a API valida se a propriedade (ou a safra)
/// pertence a ele. A despesa da compra é criada pela própria API no cadastro.
/// Nomes e assinaturas públicas são os mesmos da versão SQLite, exceto o
/// registro de consumo, que agora é uma única operação na API.
class EstoqueRepository {
  static const String _caminho = '/api/Estoque';

  static EstoqueItem _doJson(Map<String, dynamic> json) {
    return EstoqueItem(
      id: jsonIntOuNulo(json['id']),
      propriedadeId: jsonInt(json['propriedadeId']),
      nome: (json['nome'] ?? '') as String,
      categoria: (json['categoria'] ?? '') as String,
      quantidadeInicial: jsonDouble(json['quantidadeInicial']),
      quantidadeAtual: jsonDouble(json['quantidadeAtual']),
      unidadeMedida: (json['unidadeMedida'] ?? '') as String,
      precoMedioUnitario: jsonDouble(json['precoMedioUnitario']),
      estoqueMinimo: jsonDouble(json['estoqueMinimo']),
      fornecedor: json['fornecedor'] as String?,
      observacao: json['observacao'] as String?,
    );
  }

  static String? _textoOuNulo(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;

    return valor.trim();
  }

  static Map<String, dynamic> _paraJson(EstoqueItem item) {
    return {
      'propriedadeId': item.propriedadeId,
      'nome': item.nome.trim(),
      'categoria': item.categoria.trim(),
      'quantidadeInicial': item.quantidadeInicial,
      'quantidadeAtual': item.quantidadeAtual,
      'unidadeMedida': item.unidadeMedida.trim(),
      'precoMedioUnitario': item.precoMedioUnitario,
      'estoqueMinimo': item.estoqueMinimo,
      'fornecedor': _textoOuNulo(item.fornecedor),
      'observacao': _textoOuNulo(item.observacao),
    };
  }

  /// Mantém o formato usado pelo resumo da safra (chaves da consulta SQLite).
  static Map<String, dynamic> _consumoDoJson(Map<String, dynamic> json) {
    return {
      'nome': json['nome'],
      'categoria': json['categoria'],
      'unidade_medida': json['unidadeMedida'],
      'quantidade_utilizada': jsonDouble(json['quantidadeUtilizada']),
      'valor_total': jsonDouble(json['valorTotal']),
      'data_movimentacao': json['dataMovimentacao'],
      'observacao': json['observacao'],
    };
  }

  /// Insere um novo item de estoque e devolve o ID gerado pela API.
  ///
  /// A API registra a despesa da compra (quantidade inicial × preço médio)
  /// na mesma transação.
  Future<int> inserir(EstoqueItem item) async {
    final data = await ApiClient.post(_caminho, corpo: _paraJson(item));

    return jsonInt((data as Map)['id']);
  }

  /// Registra o consumo de um insumo na safra (baixa o saldo e grava o
  /// consumo na mesma transação, na API).
  Future<void> registrarConsumoSafra({
    required int safraId,
    required int estoqueItemId,
    required double quantidade,
    String? observacao,
  }) async {
    await ApiClient.post(
      '$_caminho/consumo-safra',
      corpo: {
        'safraId': safraId,
        'estoqueItemId': estoqueItemId,
        'quantidade': quantidade,
        'observacao': _textoOuNulo(observacao),
      },
    );
  }

  /// Baixa uma quantidade do item, sem vínculo com safra.
  Future<void> consumir({
    required int estoqueItemId,
    required double quantidade,
  }) async {
    await ApiClient.post(
      '$_caminho/$estoqueItemId/consumir',
      query: {'quantidade': '$quantidade'},
    );
  }

  /// Lista os itens de estoque da propriedade (ordem alfabética).
  Future<List<EstoqueItem>> listarPorPropriedadeId(int propriedadeId) async {
    final data = await ApiClient.get('$_caminho/propriedade/$propriedadeId');

    return jsonLista(data).map(_doJson).toList();
  }

  /// Lista as vacinas disponíveis em estoque (saldo maior que zero).
  Future<List<EstoqueItem>> listarVacinasDisponiveisPorPropriedade(
    int propriedadeId,
  ) async {
    final data = await ApiClient.get(
      '$_caminho/propriedade/$propriedadeId/vacinas',
    );

    return jsonLista(data).map(_doJson).toList();
  }

  /// Busca item por nome, categoria e propriedade (sem diferenciar maiúsculas).
  Future<EstoqueItem?> buscarPorNomeCategoriaEPropriedade({
    required int propriedadeId,
    required String nome,
    required String categoria,
  }) async {
    final itens = await listarPorPropriedadeId(propriedadeId);
    final nomeTratado = nome.trim().toLowerCase();
    final categoriaTratada = categoria.trim().toLowerCase();

    for (final item in itens) {
      if (item.nome.trim().toLowerCase() == nomeTratado &&
          item.categoria.trim().toLowerCase() == categoriaTratada) {
        return item;
      }
    }

    return null;
  }

  /// Busca um item específico pelo ID (null se não existir ou não for do usuário).
  Future<EstoqueItem?> buscarPorId(int id) async {
    try {
      final data = await ApiClient.get('$_caminho/$id');

      if (data is! Map) return null;

      return _doJson(Map<String, dynamic>.from(data));
    } on ApiException catch (erro) {
      if (erro.naoEncontrado) return null;

      rethrow;
    }
  }

  /// Atualiza os dados de um item (não altera a despesa da compra).
  Future<int> atualizar(EstoqueItem item) async {
    await ApiClient.put('$_caminho/${item.id}', corpo: _paraJson(item));

    return 1;
  }

  /// Verifica se a safra já possui algum consumo registrado.
  Future<bool> existeConsumoPorSafra(int safraId) async {
    final data = await ApiClient.get('$_caminho/consumos/safra/$safraId');

    return jsonLista(data).isNotEmpty;
  }

  /// Remove um item do estoque (a despesa da compra permanece no Financeiro).
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/$id');

    return 1;
  }

  /// Verifica se existe consumo de insumo por safra e categoria.
  ///
  /// Exemplo:
  /// - Sementes -> Plantio
  /// - Fertilizantes -> Fertilização
  /// - Defensivos -> Pulverização
  Future<bool> existeConsumoPorSafraECategoria({
    required int safraId,
    required String categoria,
  }) async {
    final data = await ApiClient.get(
      '$_caminho/consumos/safra/$safraId',
      query: {'categoria': categoria},
    );

    return jsonLista(data).isNotEmpty;
  }

  /// Busca o último consumo de uma safra por categoria de estoque.
  ///
  /// Usado para montar o resumo operacional da safra com:
  /// item utilizado, quantidade, unidade e data.
  Future<Map<String, dynamic>?> buscarUltimoConsumoPorCategoria({
    required int safraId,
    required String categoria,
  }) async {
    final data = await ApiClient.get(
      '$_caminho/consumos/safra/$safraId/ultimo',
      query: {'categoria': categoria},
    );

    if (data is! Map) return null;

    return _consumoDoJson(Map<String, dynamic>.from(data));
  }
}
