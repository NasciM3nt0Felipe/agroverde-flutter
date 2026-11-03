import '../../domain/entities/animal.dart';
import '../api/api_client.dart';
import '../api/api_datas.dart';
import '../api/api_json.dart';

/// Animais do rebanho — via API (/api/Animal).
///
/// O usuário vem do token JWT e a API só devolve animais das propriedades
/// dele. Nomes e assinaturas públicas são os mesmos da versão SQLite.
class RebanhoRepository {
  static const String _caminho = '/api/Animal';

  static Animal _doJson(Map<String, dynamic> json) {
    return Animal(
      id: jsonIntOuNulo(json['id']),
      propriedadeId: jsonInt(json['propriedadeId']),
      identificacao: (json['identificacao'] ?? '') as String,
      especie: (json['especie'] ?? '') as String,
      raca: json['raca'] as String?,
      sexo: (json['sexo'] ?? '') as String,
      dataNascimento: json['dataNascimento'] as String?,
      peso: jsonDoubleOuNulo(json['peso']),
      status: (json['status'] ?? '') as String,
      observacao: json['observacao'] as String?,
    );
  }

  static Map<String, dynamic> _paraJson(Animal animal) {
    return {
      'propriedadeId': animal.propriedadeId,
      'identificacao': animal.identificacao.trim(),
      'especie': animal.especie.trim(),
      'raca': textoOuNulo(animal.raca),
      'sexo': animal.sexo.trim(),
      'dataNascimento': textoOuNulo(animal.dataNascimento),
      'peso': animal.peso,
      'status': animal.status.trim(),
      'observacao': textoOuNulo(animal.observacao),
    };
  }

  /// Cadastra o animal e devolve o ID gerado pela API.
  Future<int> inserir(Animal animal) async {
    final data = await ApiClient.post(_caminho, corpo: _paraJson(animal));

    return jsonInt((data as Map)['id']);
  }

  /// Animais de todas as propriedades do usuário.
  Future<List<Animal>> listar() async {
    final data = await ApiClient.get(_caminho);

    return jsonLista(data).map(_doJson).toList();
  }

  /// Animais da propriedade (mais recentes primeiro).
  Future<List<Animal>> listarPorPropriedadeId(int propriedadeId) async {
    final data = await ApiClient.get('$_caminho/propriedade/$propriedadeId');

    return jsonLista(data).map(_doJson).toList();
  }

  Future<int> atualizar(Animal animal) async {
    await ApiClient.put('$_caminho/${animal.id}', corpo: _paraJson(animal));

    return 1;
  }

  /// Exclui o animal e seus registros (pesagens, vacinações, etc.).
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/$id');

    return 1;
  }
}
