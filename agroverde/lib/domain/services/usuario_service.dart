import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../data/sqlite/usuario_repository.dart';
import 'sessao_service.dart';

class UsuarioService {
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  String gerarHashSenha(String senha) {
    final bytes = utf8.encode(senha);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  Future<String?> alterarSenha({
    required String senhaAtual,
    required String novaSenha,
    required String confirmarSenha,
  }) async {
    final usuario = SessaoService.usuarioLogado;

    // Verifica se existe usuário autenticado
    if (usuario == null || usuario.id == null) {
      return 'Usuário não autenticado.';
    }

    // Verifica campos vazios
    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmarSenha.isEmpty) {
      return 'Preencha todos os campos.';
    }

    // Verifica a senha atual
    final senhaAtualHash = gerarHashSenha(senhaAtual);

    if (senhaAtualHash != usuario.senha) {
      return 'A senha atual está incorreta.';
    }

    // Confirmação da nova senha
    if (novaSenha != confirmarSenha) {
      return 'As novas senhas não coincidem.';
    }

    // Tamanho mínimo
    if (novaSenha.length < 6) {
      return 'A nova senha deve possuir pelo menos 6 caracteres.';
    }

    // Gera o hash da nova senha
    final novaSenhaHash = gerarHashSenha(novaSenha);

    // Não permite repetir a senha atual
    if (novaSenhaHash == usuario.senha) {
      return 'A nova senha deve ser diferente da senha atual.';
    }

    // Atualiza a senha no banco
    final resultado = await _usuarioRepository.atualizarSenha(
      usuario.id!,
      novaSenhaHash,
    );

    if (resultado == 0) {
      return 'Não foi possível alterar a senha.';
    }

    // Atualiza a senha do usuário mantido na sessão
    usuario.senha = novaSenhaHash;

    return null;
  }
}
