import '../entities/usuario.dart';
import '../entities/propriedade.dart';

class SessaoService {
  static Usuario? usuarioLogado;
  static Propriedade? propriedadeSelecionada;

  static void definirUsuario(Usuario usuario) {
    usuarioLogado = usuario;
  }

  static void definirPropriedade(Propriedade propriedade) {
    propriedadeSelecionada = propriedade;
  }

  static void limparPropriedade() {
    propriedadeSelecionada = null;
  }

  static int get usuarioId {
    return usuarioLogado!.id!;
  }

  static int? get propriedadeId {
    return propriedadeSelecionada?.id;
  }

  static String? get propriedadeNome {
    return propriedadeSelecionada?.nome;
  }
}
