import '../entities/usuario.dart';
import '../entities/propriedade.dart';

/// Mantém os dados da sessão do usuário.
class SessaoService {
  static Usuario? usuarioLogado;
  static Propriedade? propriedadeSelecionada;

  /// Define o usuário autenticado.
  static void definirUsuario(Usuario usuario) {
    usuarioLogado = usuario;
  }

  /// Define a propriedade em foco.
  static void definirPropriedade(Propriedade propriedade) {
    propriedadeSelecionada = propriedade;
  }

  /// Remove a propriedade selecionada da sessão.
  static void limparPropriedade() {
    propriedadeSelecionada = null;
  }

  /// Retorna o ID do usuário logado.
  static int get usuarioId {
    return usuarioLogado!.id!;
  }

  /// Retorna o ID da propriedade selecionada.
  static int? get propriedadeId {
    return propriedadeSelecionada?.id;
  }

  /// Retorna o nome da propriedade selecionada.
  static String? get propriedadeNome {
    return propriedadeSelecionada?.nome;
  }
}
