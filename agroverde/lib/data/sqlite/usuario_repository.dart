import 'database_helper.dart';
import '../../domain/entities/usuario.dart';

/// Responsável pelas operações de usuários.
class UsuarioRepository {
  /// Insere um novo usuário.
  Future<int> inserir(Usuario usuario) async {
    final db = await DatabaseHelper.database;

    return await db.insert('usuario', usuario.toMap());
  }

  /// Lista todos os usuários cadastrados.
  Future<List<Usuario>> listarTodos() async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query('usuario');

    return maps.map((map) => Usuario.fromMap(map)).toList();
  }

  /// Busca um usuário pelo e-mail.
  Future<Usuario?> buscarPorEmail(String email) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'usuario',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Usuario.fromMap(resultado.first);
  }
}
