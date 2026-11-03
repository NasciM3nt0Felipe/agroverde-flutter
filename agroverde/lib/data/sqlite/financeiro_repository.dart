import '../../domain/entities/lancamento_financeiro.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/api_json.dart';

/// Responsável pelas operações financeiras — via API (/api/Financeiro).
///
/// O usuário vem do token JWT e a propriedade é validada pela API: o app nunca
/// consegue ler ou alterar lançamentos de propriedades de outros usuários.
/// Nomes e assinaturas públicas são os mesmos da versão SQLite, por isso
/// as telas e services que já usavam este repositório não mudam.
///
/// Conversões feitas aqui:
/// - tipo: 'receita'/'despesa' (app) <-> 1/2 no envio e "Receita"/"Despesa"
///   no retorno (API);
/// - data: o app envia ISO completo, aaaa-MM-dd ou dd/MM/aaaa; a API recebe
///   aaaa-MM-dd;
/// - status: "Pago"/"Pendente"/"Cancelado" (API) -> minúsculas (app).
///
/// safraId NÃO é enviado: as safras do app ainda estão no SQLite local e
/// seus IDs não correspondem aos da API.
class FinanceiroRepository {
  static const String _caminho = '/api/Financeiro';

  static int _tipoParaApi(String tipo) {
    switch (tipo.trim().toLowerCase()) {
      case 'receita':
        return 1;
      case 'despesa':
        return 2;
      default:
        throw Exception('Tipo de lançamento inválido.');
    }
  }

  static String _tipoDaApi(dynamic valor) {
    if (valor is num) return valor.toInt() == 1 ? 'receita' : 'despesa';

    final texto = (valor ?? '').toString().trim().toLowerCase();

    return texto == 'receita' ? 'receita' : 'despesa';
  }

  /// Envia o status só quando não for o padrão da API (Pago).
  static int? _statusParaApi(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pendente':
        return 1;
      case 'cancelado':
        return 3;
      default:
        return null;
    }
  }

  static String _statusDaApi(dynamic valor) {
    if (valor is num) {
      switch (valor.toInt()) {
        case 1:
          return 'pendente';
        case 3:
          return 'cancelado';
        default:
          return 'pago';
      }
    }

    final texto = (valor ?? '').toString().trim().toLowerCase();

    if (texto == 'pendente' || texto == 'cancelado') return texto;

    return 'pago';
  }

  /// Converte a data recebida do app para aaaa-MM-dd.
  ///
  /// Aceita ISO completo (2026-11-03T10:00:00), aaaa-MM-dd e dd/MM/aaaa.
  /// Retorna null quando vazia: a API usa a data de hoje.
  static String? _dataParaApi(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;

    final texto = valor.trim();
    String iso;

    if (texto.contains('/')) {
      final partes = texto.split('/');

      if (partes.length != 3 || partes[2].length != 4) {
        throw Exception('Data inválida. Use o formato dd/MM/aaaa.');
      }

      iso =
          '${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}';
    } else {
      iso = texto.length >= 10 ? texto.substring(0, 10) : texto;
    }

    final convertida = DateTime.tryParse(iso);

    if (convertida == null) {
      throw Exception('Data inválida. Use o formato dd/MM/aaaa.');
    }

    // Rejeita datas inexistentes, como 31/02, que o DateTime "ajustaria".
    final normalizada =
        '${convertida.year.toString().padLeft(4, '0')}-'
        '${convertida.month.toString().padLeft(2, '0')}-'
        '${convertida.day.toString().padLeft(2, '0')}';

    if (normalizada != iso) {
      throw Exception('Data inválida. Use o formato dd/MM/aaaa.');
    }

    return iso;
  }

  /// Mantém a data como aaaa-MM-dd (formato já aceito pelo app).
  static String? _dataDaApi(dynamic valor) {
    if (valor is! String || valor.length < 10) return null;

    return valor.substring(0, 10);
  }

  /// Arredonda para centavos (a API grava decimal com 2 casas).
  static double _valorParaApi(double valor) {
    return double.parse(valor.toStringAsFixed(2));
  }

  static LancamentoFinanceiro _doJson(Map<String, dynamic> json) {
    return LancamentoFinanceiro(
      id: jsonIntOuNulo(json['id']),
      propriedadeId: jsonInt(json['propriedadeId']),
      descricao: (json['descricao'] ?? '') as String,
      valor: jsonDouble(json['valor']),
      tipo: _tipoDaApi(json['tipo']),
      data: _dataDaApi(json['data']) ??
          _dataDaApi(json['dataVencimento']) ??
          '',
      safraId: jsonIntOuNulo(json['safraId']),
      status: _statusDaApi(json['status']),
      categoria: json['categoria'] as String?,
      dataVencimento: _dataDaApi(json['dataVencimento']),
      dataPagamento: _dataDaApi(json['dataPagamento']),
      origemTipo: json['origemTipo'] as String?,
      // Ausentes em versões antigas da API: assume permitido
      // (a API continua validando cada operação).
      permiteEditar: json['permiteEditar'] is bool
          ? json['permiteEditar'] as bool
          : true,
      permiteExcluir: json['permiteExcluir'] is bool
          ? json['permiteExcluir'] as bool
          : true,
    );
  }

  static void _validarPropriedade(int propriedadeId) {
    if (propriedadeId <= 0) {
      throw Exception('Selecione uma propriedade em foco primeiro.');
    }
  }

  /// Insere um novo lançamento financeiro e devolve o id gerado pela API.
  Future<int> inserir(LancamentoFinanceiro lancamento) async {
    _validarPropriedade(lancamento.propriedadeId);

    final corpo = <String, dynamic>{
      'propriedadeId': lancamento.propriedadeId,
      'descricao': lancamento.descricao.trim(),
      'valor': _valorParaApi(lancamento.valor),
      'tipo': _tipoParaApi(lancamento.tipo),
      'data': _dataParaApi(lancamento.data),
      'categoria': lancamento.categoria,
      'dataVencimento': _dataParaApi(lancamento.dataVencimento),
      'status': _statusParaApi(lancamento.status),
      // Identifica lançamentos automáticos (folha, veículos, colheita...).
      'origemTipo': lancamento.origemTipo,
    };

    final data = await ApiClient.post(_caminho, corpo: corpo);

    if (data is! Map) {
      throw ApiException('Resposta inesperada da API ao salvar o lançamento.');
    }

    return jsonInt(data['id']);
  }

  /// Lista os lançamentos da propriedade (mais recentes primeiro).
  Future<List<LancamentoFinanceiro>> listarPorPropriedadeId(
    int propriedadeId,
  ) async {
    _validarPropriedade(propriedadeId);

    final data = await ApiClient.get(
      _caminho,
      query: {'propriedadeId': '$propriedadeId'},
    );

    // O filtro local garante o resultado mesmo em uma API que ainda
    // não reconheça o parâmetro propriedadeId.
    final lista = jsonLista(data)
        .map(_doJson)
        .where((l) => l.propriedadeId == propriedadeId)
        .toList();

    lista.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    return lista;
  }

  /// Atualiza um lançamento financeiro.
  ///
  /// Data, status, categoria e safra não são enviados: a API mantém
  /// os valores atuais, preservando a data original do lançamento.
  Future<int> atualizar(LancamentoFinanceiro lancamento) async {
    if (lancamento.id == null) {
      throw Exception('Lançamento inválido.');
    }

    _validarPropriedade(lancamento.propriedadeId);

    await ApiClient.put(
      '$_caminho/${lancamento.id}',
      corpo: {
        'propriedadeId': lancamento.propriedadeId,
        'descricao': lancamento.descricao.trim(),
        'valor': _valorParaApi(lancamento.valor),
        'tipo': _tipoParaApi(lancamento.tipo),
      },
    );

    return 1;
  }

  /// Lista apenas os lançamentos de uma origem automática na propriedade.
  ///
  /// Usado para evitar lançamentos repetidos (ex.: folha já lançada).
  Future<List<LancamentoFinanceiro>> listarPorOrigem({
    required int propriedadeId,
    required String origemTipo,
  }) async {
    final lista = await listarPorPropriedadeId(propriedadeId);

    return lista.where((l) => l.origemTipo == origemTipo).toList();
  }

  /// Remove um lançamento financeiro.
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/$id');

    return 1;
  }
}
