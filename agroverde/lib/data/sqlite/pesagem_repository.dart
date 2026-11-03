import '../../domain/entities/pesagem_rebanho.dart';
import '../../domain/services/sessao_service.dart';
import '../api/api_client.dart';
import '../api/api_datas.dart';
import '../api/api_json.dart';

/// Pesagens do rebanho — via API (/api/Animal/...).
///
/// A API só aceita animais e registros das propriedades do usuário do token.
class PesagemRepository {
  static const String _caminho = '/api/Animal';

  static PesagemRebanho _doJson(Map<String, dynamic> json) {
    return PesagemRebanho(
      id: jsonIntOuNulo(json['id']),
      animalId: jsonInt(json['animalId']),
      peso: jsonDouble(json['pesoKg']),
      data: dataDaApi(json['dataPesagem']),
      observacao: json['observacao'] as String?,
    );
  }

  Future<int> inserir(PesagemRebanho registro) async {
    final data = await ApiClient.post(
      '$_caminho/pesagens',
      corpo: {
        'animalId': registro.animalId,
        'pesoKg': registro.peso,
        'dataPesagem': dataParaApi(registro.data, campo: 'data da pesagem'),
        'observacao': textoOuNulo(registro.observacao),
      },
    );

    return jsonInt((data as Map)['id']);
  }

  /// Registros da propriedade em foco (mais recentes primeiro).
  Future<List<PesagemRebanho>> listar() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) return [];

    return listarPorPropriedadeId(propriedadeId);
  }

  Future<List<PesagemRebanho>> listarPorPropriedadeId(int propriedadeId) async {
    final data = await ApiClient.get(
      '$_caminho/propriedade/$propriedadeId/pesagens',
    );

    return jsonLista(data).map(_doJson).toList();
  }

  Future<List<PesagemRebanho>> listarPorAnimal(int animalId) async {
    final data = await ApiClient.get('$_caminho/$animalId');

    if (data is! Map) return [];

    return jsonLista(data['pesagens']).map(_doJson).toList();
  }

  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/pesagens/$id');

    return 1;
  }
}
