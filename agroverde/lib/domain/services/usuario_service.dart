import '../../data/api/api_client.dart';
import '../../data/api/api_exception.dart';
import 'sessao_service.dart';

class UsuarioService {
  Future<String?> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarSenha,
  }) async {
    final usuario = SessaoService.usuarioLogado;

    if (usuario == null || usuario.id == null || ApiClient.token == null) {
      return 'Usuário não autenticado.';
    }

    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmarSenha.isEmpty) {
      return 'Preencha todos os campos.';
    }

    if (novaSenha != confirmarSenha) {
      return 'As novas senhas não coincidem.';
    }

    if (novaSenha.length < 6) {
      return 'A nova senha deve possuir pelo menos 6 caracteres.';
    }

    if (senhaAtual == novaSenha) {
      return 'A nova senha deve ser diferente da senha atual.';
    }

    try {
      await ApiClient.put(
        '/api/Auth/senha',
        corpo: {'senhaAtual': senhaAtual, 'novaSenha': novaSenha},
      );

      return null;
    } on ApiException catch (erro) {
      return erro.message;
    } catch (_) {
      return 'Não foi possível alterar a senha.';
    }
  }
}
