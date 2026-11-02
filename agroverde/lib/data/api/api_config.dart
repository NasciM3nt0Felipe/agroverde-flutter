import 'package:flutter/foundation.dart';

// Classe responsável pelas configurações de comunicação
// entre o aplicativo Flutter e a API .NET 8 do AgroVerde.
class ApiConfig {
  // Permite informar o endereço da API ao executar o Flutter.
  //
  // Exemplo:
  // flutter run --dart-define=API_BASE_URL=http://192.168.0.10:5114
  //
  // Se nenhum endereço for informado, a variável fica vazia.
  static const String _urlDefinida = String.fromEnvironment('API_BASE_URL');

  // Retorna o endereço que o Flutter utilizará
  // para enviar as requisições HTTP à API.
  static String get baseUrl {
    // Primeiro, verifica se o endereço foi informado
    // manualmente pelo parâmetro API_BASE_URL.
    if (_urlDefinida.isNotEmpty) {
      // Remove a barra final, caso exista.
      // Isso evita endereços com duas barras, como:
      // http://localhost:5114//api/Auth/login
      return _urlDefinida.endsWith('/')
          ? _urlDefinida.substring(0, _urlDefinida.length - 1)
          : _urlDefinida;
    }

    // Se estiver executando no emulador Android,
    // utiliza 10.0.2.2 para acessar o computador.
    //
    // No emulador, localhost aponta para o próprio
    // dispositivo virtual, e não para o Windows.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5114';
    }

    // Endereço padrão utilizado pelo Flutter Desktop
    // no Windows, onde estamos desenvolvendo o AgroVerde.
    //
    // A API .NET deve estar executando na porta 5114.
    return 'http://localhost:5114';
  }

  // Define quanto tempo o Flutter aguardará
  // pela resposta de uma requisição HTTP.
  //
  // Se a API demorar mais de 20 segundos,
  // o ApiClient poderá interromper a espera.
  static const Duration timeout = Duration(seconds: 20);

  // Informa que a API já possui a regra responsável
  // por gerar automaticamente uma despesa financeira
  // quando um item de estoque é cadastrado.
  //
  // true = a API registra a despesa.
  // false = o Flutter tenta registrar a despesa.
  //
  // IMPORTANTE:
  // Manter true porque já implementamos essa regra
  // na API .NET 8.
  //
  // Alterar para false com a regra ativa na API
  // poderá gerar despesas duplicadas.
  static const bool apiGeraDespesaEstoque = true;
}
