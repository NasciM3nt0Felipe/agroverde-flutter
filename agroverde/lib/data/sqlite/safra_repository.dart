import '../../domain/entities/safra.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/api_json.dart';

/// Responsável pelas operações de safras — via API (/api/Safra).
///
/// A API valida se o talhão existe e pertence a uma propriedade do usuário,
/// impede transferir a safra para outra propriedade e mantém a regra de uma
/// safra ativa por talhão. Nomes e assinaturas públicas são os mesmos da
/// versão SQLite.
///
/// Fluxo:
/// Propriedade -> Talhão -> Safra
class SafraRepository {
  static const String _caminho = '/api/Safra';

  static String? _textoOuNulo(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;

    return valor.trim();
  }

  static Safra _doJson(Map<String, dynamic> json) {
    return Safra(
      id: jsonIntOuNulo(json['id']),
      talhaoId: jsonInt(json['talhaoId']),
      nome: (json['nome'] ?? '') as String,
      cultura: (json['cultura'] ?? '') as String,
      variedade: json['variedade'] as String?,
      dataPlantio: (json['dataPlantio'] ?? '') as String,
      dataColheitaPrevista: json['dataColheitaPrevista'] as String?,
      dataColheitaReal: json['dataColheitaReal'] as String?,
      producaoEstimada: jsonDoubleOuNulo(json['producaoEstimada']),
      producaoObtida: jsonDoubleOuNulo(json['producaoObtida']),
      status: (json['status'] ?? 'Planejada') as String,
      observacao: json['observacao'] as String?,
    );
  }

  static Map<String, dynamic> _paraJson(Safra safra) {
    return {
      'talhaoId': safra.talhaoId,
      'nome': safra.nome.trim(),
      'cultura': safra.cultura.trim(),
      'variedade': _textoOuNulo(safra.variedade),
      'dataPlantio': safra.dataPlantio.trim(),
      'dataColheitaPrevista': _textoOuNulo(safra.dataColheitaPrevista),
      'dataColheitaReal': _textoOuNulo(safra.dataColheitaReal),
      'producaoEstimada': safra.producaoEstimada,
      'producaoObtida': safra.producaoObtida,
      'status': safra.status,
      'observacao': _textoOuNulo(safra.observacao),
    };
  }

  /// Insere uma nova safra e devolve o ID gerado pela API.
  Future<int> inserir(Safra safra) async {
    final data = await ApiClient.post(_caminho, corpo: _paraJson(safra));

    return jsonInt((data as Map)['id']);
  }

  /// Lista as safras de um talhão (mais recentes primeiro).
  Future<List<Safra>> listarPorTalhaoId(int talhaoId) async {
    final data = await ApiClient.get('$_caminho/talhao/$talhaoId');

    return jsonLista(data).map(_doJson).toList();
  }

  /// Lista as safras disponíveis para colheita na propriedade.
  ///
  /// Critérios (aplicados pela API):
  /// - possuem data de colheita prevista menor ou igual à data atual;
  /// - ainda não estão com status Colhida ou Finalizada.
  Future<List<Safra>> listarDisponiveisParaColheitaPorPropriedade(
    int propriedadeId,
  ) async {
    final data = await ApiClient.get(
      '$_caminho/disponiveis-colheita/propriedade/$propriedadeId',
    );

    return jsonLista(data).map(_doJson).toList();
  }

  /// Verifica se já existe uma safra ativa no talhão.
  ///
  /// Status considerados ativos: Planejada e Em andamento.
  /// O parâmetro ignorarSafraId é usado na edição. A API também valida.
  Future<bool> existeSafraAtiva(int talhaoId, {int? ignorarSafraId}) async {
    final safras = await listarPorTalhaoId(talhaoId);

    return safras.any(
      (s) =>
          s.id != ignorarSafraId &&
          (s.status == 'Planejada' || s.status == 'Em andamento'),
    );
  }

  /// Atualiza os dados de uma safra existente.
  Future<int> atualizar(Safra safra) async {
    await ApiClient.put('$_caminho/${safra.id}', corpo: _paraJson(safra));

    return 1;
  }

  /// Exclui uma safra (a API recusa se houver consumos ou lançamentos vinculados).
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/$id');

    return 1;
  }

  /// Busca uma safra pelo ID (null se não existir ou não for do usuário).
  Future<Safra?> buscarPorId(int id) async {
    try {
      final data = await ApiClient.get('$_caminho/$id');

      if (data is! Map) return null;

      return _doJson(Map<String, dynamic>.from(data));
    } on ApiException catch (erro) {
      if (erro.naoEncontrado) return null;

      rethrow;
    }
  }
}
