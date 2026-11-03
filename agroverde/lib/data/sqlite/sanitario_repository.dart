import '../../domain/entities/sanitario_rebanho.dart';
import '../../domain/services/sessao_service.dart';
import '../api/api_client.dart';
import '../api/api_datas.dart';
import '../api/api_json.dart';

/// Controle sanitário do rebanho — via API (/api/Animal/...).
///
/// A API só aceita animais e registros das propriedades do usuário do token.
class SanitarioRepository {
  static const String _caminho = '/api/Animal';

  static SanitarioRebanho _doJson(Map<String, dynamic> json) {
    return SanitarioRebanho(
      id: jsonIntOuNulo(json['id']),
      animalId: jsonInt(json['animalId']),
      procedimento: (json['procedimento'] ?? '') as String,
      data: dataDaApi(json['data']),
      medicamento: json['medicamento'] as String?,
      observacao: json['observacao'] as String?,
    );
  }

  Future<int> inserir(SanitarioRebanho registro) async {
    final data = await ApiClient.post(
      '$_caminho/sanitario',
      corpo: {
        'animalId': registro.animalId,
        'procedimento': registro.procedimento.trim(),
        'data': dataParaApi(registro.data),
        'medicamento': textoOuNulo(registro.medicamento),
        'observacao': textoOuNulo(registro.observacao),
      },
    );

    return jsonInt((data as Map)['id']);
  }

  /// Registros da propriedade em foco (mais recentes primeiro).
  Future<List<SanitarioRebanho>> listar() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) return [];

    return listarPorPropriedadeId(propriedadeId);
  }

  Future<List<SanitarioRebanho>> listarPorPropriedadeId(int propriedadeId) async {
    final data = await ApiClient.get(
      '$_caminho/propriedade/$propriedadeId/sanitario',
    );

    return jsonLista(data).map(_doJson).toList();
  }

  Future<List<SanitarioRebanho>> listarPorAnimal(int animalId) async {
    final data = await ApiClient.get('$_caminho/$animalId');

    if (data is! Map) return [];

    return jsonLista(data['controlesSanitarios']).map(_doJson).toList();
  }

  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/sanitario/$id');

    return 1;
  }
}
