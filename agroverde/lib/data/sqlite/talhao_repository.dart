import '../../domain/entities/talhao.dart';
import '../api/api_client.dart';
import '../api/api_json.dart';

/// Responsável pelas operações de talhões — via API (/api/Talhao).
///
/// O usuário vem do token JWT e a API valida se a propriedade pertence a ele.
/// A API também aplica a regra dos 90% da área da propriedade e impede excluir
/// talhões com safras vinculadas. Nomes e assinaturas públicas são os mesmos
/// da versão SQLite.
class TalhaoRepository {
  static const String _caminho = '/api/Talhao';

  static Talhao _doJson(Map<String, dynamic> json) {
    return Talhao(
      id: jsonIntOuNulo(json['id']),
      propriedadeId: jsonInt(json['propriedadeId']),
      nome: (json['nome'] ?? '') as String,
      area: jsonDouble(json['area']),
      tipoSolo: json['tipoSolo'] as String?,
      observacao: json['observacao'] as String?,
      ativo: json['ativo'] is bool ? json['ativo'] as bool : true,
    );
  }

  static Map<String, dynamic> _paraJson(Talhao talhao) {
    return {
      'propriedadeId': talhao.propriedadeId,
      'nome': talhao.nome.trim(),
      'area': talhao.area,
      'tipoSolo': talhao.tipoSolo,
      'observacao': talhao.observacao,
      'ativo': talhao.ativo,
    };
  }

  /// Insere um novo talhão e devolve o ID gerado pela API.
  Future<int> inserir(Talhao talhao) async {
    final data = await ApiClient.post(_caminho, corpo: _paraJson(talhao));

    return jsonInt((data as Map)['id']);
  }

  /// Lista os talhões da propriedade (ordem alfabética, como antes).
  Future<List<Talhao>> listarPorPropriedadeId(int propriedadeId) async {
    final data = await ApiClient.get('$_caminho/propriedade/$propriedadeId');

    return jsonLista(data).map(_doJson).toList();
  }

  /// Atualiza um talhão já existente.
  Future<int> atualizar(Talhao talhao) async {
    await ApiClient.put('$_caminho/${talhao.id}', corpo: _paraJson(talhao));

    return 1;
  }

  /// Remove um talhão (a API recusa se houver safras vinculadas).
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/$id');

    return 1;
  }
}
