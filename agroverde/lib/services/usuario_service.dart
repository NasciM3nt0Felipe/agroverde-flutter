import 'dart:convert';
import 'package:crypto/crypto.dart';

class UsuarioService {
  String gerarHashSenha(String senha) {
    final bytes = utf8.encode(senha);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }
}
