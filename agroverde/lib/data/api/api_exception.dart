/// Representa um erro ocorrido durante a comunicação
/// entre o Flutter e a API .NET 8.
///
/// Implementamos Exception para que o erro possa ser
/// lançado com throw e capturado com try/catch.
class ApiException implements Exception {
  // Mensagem que explica o erro ocorrido.
  //
  // Exemplos:
  // "E-mail ou senha inválidos."
  // "Propriedade não encontrada."
  // "Sessão expirada."
  final String message;

  // Código HTTP retornado pela API.
  //
  // Exemplos:
  // 400 = Requisição inválida.
  // 401 = Usuário não autenticado.
  // 403 = Acesso proibido.
  // 404 = Registro não encontrado.
  // 500 = Erro interno do servidor.
  //
  // O ponto de interrogação indica que o valor
  // pode ser nulo, como em uma falha de conexão.
  final int? statusCode;

  // Construtor utilizado para criar um erro.
  //
  // A mensagem é obrigatória.
  // O código HTTP é opcional.
  //
  // Exemplo:
  // ApiException(
  //   'Propriedade não encontrada.',
  //   statusCode: 404,
  // );
  ApiException(this.message, {this.statusCode});

  // Retorna true quando a API responde HTTP 404.
  //
  // Isso permite que os repositórios identifiquem
  // facilmente quando um registro não existe.
  bool get naoEncontrado => statusCode == 404;

  // Define como o erro será convertido para texto.
  //
  // Mantemos o prefixo "Exception: " porque algumas
  // telas existentes do AgroVerde já removem esse
  // prefixo antes de mostrar a mensagem ao usuário.
  @override
  String toString() => 'Exception: $message';
}
