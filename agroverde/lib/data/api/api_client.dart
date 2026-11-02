import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP centralizado do AgroVerde.
///
/// Todas as chamadas à API passam por esta classe,
/// evitando repetir código de conexão nos repositórios.
class ApiClient {
  // Guarda temporariamente o token JWT do usuário.
  // O token será utilizado nas requisições autenticadas.
  static String? _token;

  // Função executada quando a API responde HTTP 401.
  // Será configurada no main.dart para voltar ao login.
  static void Function()? aoSessaoExpirada;

  // Permite consultar o token armazenado.
  static String? get token => _token;

  // Armazena ou limpa o token JWT.
  static void definirToken(String? token) {
    _token = token;
  }

  // Realiza uma requisição GET para consultar dados.
  static Future<dynamic> get(String caminho, {Map<String, String>? query}) {
    return _enviar('GET', caminho, query: query);
  }

  // Realiza uma requisição POST para cadastrar dados
  // ou executar operações na API.
  //
  // autenticado = false é usado no login e cadastro,
  // pois o usuário ainda não possui um token JWT.
  static Future<dynamic> post(
    String caminho, {
    Object? corpo,
    Map<String, String>? query,
    bool autenticado = true,
  }) {
    return _enviar(
      'POST',
      caminho,
      corpo: corpo,
      query: query,
      autenticado: autenticado,
    );
  }

  // Realiza uma requisição PUT para atualizar registros.
  static Future<dynamic> put(String caminho, {Object? corpo}) {
    return _enviar('PUT', caminho, corpo: corpo);
  }

  // Realiza uma requisição DELETE para excluir registros.
  static Future<dynamic> delete(String caminho) {
    return _enviar('DELETE', caminho);
  }

  // Método interno responsável por executar as requisições.
  //
  // O "_" no início indica que ele é privado ao arquivo.
  static Future<dynamic> _enviar(
    String metodo,
    String caminho, {
    Object? corpo,
    Map<String, String>? query,
    bool autenticado = true,
  }) async {
    // Monta a URL completa.
    //
    // Exemplo:
    // http://localhost:5114/api/Propriedade
    //
    // queryParameters acrescenta parâmetros à URL,
    // como ?propriedadeId=2.
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$caminho',
    ).replace(queryParameters: (query == null || query.isEmpty) ? null : query);

    // Cabeçalhos enviados à API.
    // Informam que trabalhamos com JSON.
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };

    // Se a chamada exigir autenticação e houver token,
    // envia o JWT no cabeçalho Authorization.
    if (autenticado && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    // Converte o corpo da requisição para JSON.
    // Exemplo: um Map Dart vira uma string JSON.
    final corpoJson = corpo == null ? null : jsonEncode(corpo);

    http.Response resposta;

    try {
      // Escolhe a operação HTTP solicitada.
      switch (metodo) {
        case 'GET':
          resposta = await http
              .get(uri, headers: headers)
              .timeout(ApiConfig.timeout);
          break;

        case 'POST':
          resposta = await http
              .post(uri, headers: headers, body: corpoJson)
              .timeout(ApiConfig.timeout);
          break;

        case 'PUT':
          resposta = await http
              .put(uri, headers: headers, body: corpoJson)
              .timeout(ApiConfig.timeout);
          break;

        case 'DELETE':
          resposta = await http
              .delete(uri, headers: headers)
              .timeout(ApiConfig.timeout);
          break;

        default:
          throw ApiException('Método HTTP não suportado: $metodo');
      }

      // A API demorou mais que o tempo configurado.
    } on TimeoutException {
      throw ApiException(
        'A API demorou para responder (${ApiConfig.baseUrl}). '
        'Verifique se ela está em execução.',
      );

      // O cliente HTTP não conseguiu completar a conexão.
    } on http.ClientException {
      throw ApiException(
        'Não foi possível conectar à API (${ApiConfig.baseUrl}). '
        'Verifique se ela está em execução e o endereço configurado.',
      );
    }

    // Tenta converter a resposta recebida em JSON.
    final corpoResposta = _decodificar(resposta);

    // HTTP 401 indica falha de autenticação.
    //
    // Em uma chamada autenticada, limpamos o token
    // e notificamos o aplicativo para voltar ao login.
    if (resposta.statusCode == 401 && autenticado) {
      _token = null;
      aoSessaoExpirada?.call();

      throw ApiException(
        'Sessão expirada. Faça login novamente.',
        statusCode: 401,
      );
    }

    // Consideramos sucesso HTTP os códigos 200 a 299.
    final sucessoHttp = resposta.statusCode >= 200 && resposta.statusCode < 300;

    // Nossa API utiliza um envelope padronizado:
    //
    // {
    //   "success": true,
    //   "message": "...",
    //   "data": {...},
    //   "errors": []
    // }
    //
    // Quando há sucesso, devolvemos apenas "data".
    if (corpoResposta is Map<String, dynamic> &&
        corpoResposta.containsKey('success')) {
      if (corpoResposta['success'] == true && sucessoHttp) {
        return corpoResposta['data'];
      }

      throw ApiException(
        _mensagemDoEnvelope(corpoResposta, resposta.statusCode),
        statusCode: resposta.statusCode,
      );
    }

    // Algumas respostas HTTP válidas podem não
    // utilizar o envelope padronizado.
    if (sucessoHttp) {
      return corpoResposta;
    }

    // Erro HTTP sem envelope reconhecido.
    throw ApiException(
      _mensagemPadrao(resposta.statusCode),
      statusCode: resposta.statusCode,
    );
  }

  // Converte os bytes da resposta HTTP em JSON.
  //
  // Retorna null se a resposta estiver vazia
  // ou não contiver JSON válido.
  static dynamic _decodificar(http.Response resposta) {
    if (resposta.bodyBytes.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  // Extrai a mensagem de erro enviada pela API.
  //
  // Prioriza detalhes de validação quando disponíveis.
  static String _mensagemDoEnvelope(
    Map<String, dynamic> envelope,
    int statusCode,
  ) {
    final mensagem = (envelope['message'] as String?)?.trim() ?? '';

    final erros = <String>[];
    final listaErros = envelope['errors'];

    if (listaErros is List) {
      for (final erro in listaErros) {
        if (erro is String && erro.trim().isNotEmpty) {
          erros.add(erro.trim());
        }
      }
    }

    if (erros.isNotEmpty &&
        (mensagem.isEmpty || mensagem.startsWith('Dados inválidos'))) {
      return erros.join('\n');
    }

    if (mensagem.isNotEmpty) {
      return mensagem;
    }

    return _mensagemPadrao(statusCode);
  }

  // Traduz códigos HTTP conhecidos para mensagens
  // mais compreensíveis ao usuário.
  static String _mensagemPadrao(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dados inválidos.';

      case 403:
        return 'Você não tem permissão para acessar este recurso.';

      case 404:
        return 'Registro não encontrado.';

      default:
        return 'Erro inesperado na API (HTTP $statusCode).';
    }
  }
}
