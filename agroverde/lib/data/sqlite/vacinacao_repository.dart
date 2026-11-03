import '../../domain/entities/vacinacao_rebanho.dart';
import '../../domain/services/sessao_service.dart';
import '../api/api_client.dart';
import '../api/api_datas.dart';
import '../api/api_json.dart';

/// Vacinações do rebanho — via API (/api/Animal/...).
///
/// O registro da vacinação e a baixa de 1 dose do estoque acontecem na
/// mesma transação, na API.
class VacinacaoRepository {
  static const String _caminho = '/api/Animal';

  static VacinacaoRebanho _doJson(Map<String, dynamic> json) {
    return VacinacaoRebanho(
      id: jsonIntOuNulo(json['id']),
      animalId: jsonInt(json['animalId']),
      vacina: (json['vacina'] ?? '') as String,
      dataAplicacao: dataDaApi(json['dataAplicacao']),
      proximaDose: dataDaApiOuNulo(json['proximaDose']),
      observacao: json['observacao'] as String?,
    );
  }

  /// Registra a vacinação e baixa 1 dose do item de estoque informado
  /// (sem o item, a API procura a vacina pelo nome no estoque).
  Future<int> inserir(VacinacaoRebanho vacinacao, {int? estoqueItemId}) async {
    final proxima = textoOuNulo(vacinacao.proximaDose);

    final data = await ApiClient.post(
      '$_caminho/vacinacoes',
      corpo: {
        'animalId': vacinacao.animalId,
        'vacina': vacinacao.vacina.trim(),
        'dataAplicacao': dataParaApi(
          vacinacao.dataAplicacao,
          campo: 'data de aplicação',
        ),
        'proximaDose': proxima == null
            ? null
            : dataParaApi(proxima, campo: 'data da próxima dose'),
        'observacao': textoOuNulo(vacinacao.observacao),
        'estoqueItemId': estoqueItemId,
      },
    );

    return jsonInt((data as Map)['id']);
  }

  /// Vacinações da propriedade em foco (mais recentes primeiro).
  Future<List<VacinacaoRebanho>> listar() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) return [];

    return listarPorPropriedadeId(propriedadeId);
  }

  Future<List<VacinacaoRebanho>> listarPorPropriedadeId(
    int propriedadeId,
  ) async {
    final data = await ApiClient.get(
      '$_caminho/propriedade/$propriedadeId/vacinacoes',
    );

    return jsonLista(data).map(_doJson).toList();
  }

  Future<List<VacinacaoRebanho>> listarPorAnimal(int animalId) async {
    final data = await ApiClient.get('$_caminho/$animalId');

    if (data is! Map) return [];

    return jsonLista(data['vacinacoes']).map(_doJson).toList();
  }

  /// Exclui o histórico (a dose aplicada não volta ao estoque).
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/vacinacoes/$id');

    return 1;
  }
}
