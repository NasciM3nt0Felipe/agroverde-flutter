import '../../domain/entities/reproducao_rebanho.dart';
import '../../domain/services/sessao_service.dart';
import '../api/api_client.dart';
import '../api/api_datas.dart';
import '../api/api_json.dart';

/// Registros de reprodução do rebanho — via API (/api/Animal/...).
///
/// A API só aceita animais e registros das propriedades do usuário do token.
class ReproducaoRepository {
  static const String _caminho = '/api/Animal';

  static ReproducaoRebanho _doJson(Map<String, dynamic> json) {
    return ReproducaoRebanho(
      id: jsonIntOuNulo(json['id']),
      animalId: jsonInt(json['animalId']),
      tipo: (json['tipo'] ?? '') as String,
      data: dataDaApi(json['data']),
      observacao: json['observacao'] as String?,
    );
  }

  Future<int> inserir(ReproducaoRebanho registro) async {
    final data = await ApiClient.post(
      '$_caminho/reproducao',
      corpo: {
        'animalId': registro.animalId,
        'tipo': registro.tipo,
        'data': dataParaApi(registro.data),
        'observacao': textoOuNulo(registro.observacao),
      },
    );

    return jsonInt((data as Map)['id']);
  }

  /// Registros da propriedade em foco (mais recentes primeiro).
  Future<List<ReproducaoRebanho>> listar() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) return [];

    return listarPorPropriedadeId(propriedadeId);
  }

  Future<List<ReproducaoRebanho>> listarPorPropriedadeId(int propriedadeId) async {
    final data = await ApiClient.get(
      '$_caminho/propriedade/$propriedadeId/reproducao',
    );

    return jsonLista(data).map(_doJson).toList();
  }

  Future<List<ReproducaoRebanho>> listarPorAnimal(int animalId) async {
    final data = await ApiClient.get('$_caminho/$animalId');

    if (data is! Map) return [];

    return jsonLista(data['reproducoes']).map(_doJson).toList();
  }

  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/reproducao/$id');

    return 1;
  }
}
