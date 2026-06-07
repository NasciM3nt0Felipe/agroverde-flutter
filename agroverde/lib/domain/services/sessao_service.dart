import '../entities/usuario.dart';

class SessaoService {
  static Usuario? usuarioLogado;

  static void definirUsuario(Usuario usuario) {
    usuarioLogado = usuario;
  }

  static int get usuarioId {
    return usuarioLogado!.id!;
  }
}
