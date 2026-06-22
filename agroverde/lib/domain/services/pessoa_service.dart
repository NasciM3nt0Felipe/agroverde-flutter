import 'dart:convert';

import 'package:http/http.dart' as http;

/// Responsável por validações e consultas de pessoas.
class PessoaService {
  /// Valida CPF pelo tamanho informado.
  bool cpfValido(String cpf) {
    return cpf.replaceAll(RegExp(r'[^0-9]'), '').length == 11;
  }

  /// Remove caracteres especiais do CEP.
  String limparCep(String cep) {
    return cep.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Verifica se o CEP possui 8 dígitos.
  bool cepValido(String cep) {
    return limparCep(cep).length == 8;
  }

  /// Busca endereço a partir do CEP informado.
  ///
  /// Consulta ViaCEP e BrasilAPI como contingência.
  Future<Map<String, String>?> buscarEnderecoPorCep(String cep) async {
    final cepLimpo = limparCep(cep);

    if (!cepValido(cepLimpo)) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);

        if (dados['erro'] != true) {
          return {
            'rua': dados['logradouro'] ?? '',
            'bairro': dados['bairro'] ?? '',
            'cidade': dados['localidade'] ?? '',
            'estado': dados['uf'] ?? '',
          };
        }
      }
    } catch (_) {}

    try {
      final response = await http
          .get(Uri.parse('https://brasilapi.com.br/api/cep/v1/$cepLimpo'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);

        return {
          'rua': dados['street'] ?? '',
          'bairro': dados['neighborhood'] ?? '',
          'cidade': dados['city'] ?? '',
          'estado': dados['state'] ?? '',
        };
      }
    } catch (_) {}

    return null;
  }
}
