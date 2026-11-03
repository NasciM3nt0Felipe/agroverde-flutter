import '../../domain/entities/propriedade.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';

/// Responsável pelas operações de propriedades — via API (/api/Propriedade).
///
/// O dono da propriedade vem sempre do token JWT: o app nunca envia usuarioId.
/// Os nomes e as assinaturas públicas são os mesmos da versão SQLite.
class PropriedadeRepository {
  static int _inteiro(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? 0;
    return 0;
  }

  static double _decimal(dynamic valor) {
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? 0.0;
    return 0.0;
  }

  static Propriedade _doJson(Map<String, dynamic> json) {
    return Propriedade(
      id: _inteiro(json['id']),
      usuarioId: _inteiro(json['usuarioId']),
      nome: (json['nome'] ?? '') as String,
      areaTotal: _decimal(json['areaTotal']),
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      descricao: json['descricao'] as String?,
    );
  }

  static Map<String, dynamic> _paraJson(Propriedade propriedade) {
    return {
      'nome': propriedade.nome,
      'areaTotal': propriedade.areaTotal,
      'cidade': propriedade.cidade,
      'estado': propriedade.estado,
      'descricao': propriedade.descricao,
    };
  }

  /// Insere uma nova propriedade e devolve o id gerado.
  Future<int> inserir(Propriedade propriedade) async {
    final data = await ApiClient.post(
      '/api/Propriedade',
      corpo: _paraJson(propriedade),
    );

    return _inteiro((data as Map)['id']);
  }

  /// Lista as propriedades do usuário logado (o parâmetro é mantido por
  /// compatibilidade; a API usa o usuário do token).
  Future<List<Propriedade>> listarPorUsuarioId(int usuarioId) async {
    final data = await ApiClient.get('/api/Propriedade');

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => _doJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Atualiza os dados da propriedade.
  Future<int> atualizar(Propriedade propriedade) async {
    await ApiClient.put(
      '/api/Propriedade/${propriedade.id}',
      corpo: _paraJson(propriedade),
    );

    return 1;
  }

  /// Remove uma propriedade. A API bloqueia (HTTP 400) se houver registros
  /// vinculados; nesse caso uma ApiException com a mensagem é lançada.
  Future<int> excluir(int id) async {
    await ApiClient.delete('/api/Propriedade/$id');

    return 1;
  }

  /// Busca uma propriedade pelo ID (null se não existir ou não for do usuário).
  Future<Propriedade?> buscarPorId(int id) async {
    try {
      final data = await ApiClient.get('/api/Propriedade/$id');

      if (data is! Map) {
        return null;
      }

      return _doJson(Map<String, dynamic>.from(data));
    } on ApiException catch (erro) {
      if (erro.naoEncontrado) {
        return null;
      }

      rethrow;
    }
  }
}
