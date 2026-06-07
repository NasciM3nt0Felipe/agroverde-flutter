import 'database_helper.dart';
import '../../domain/entities/usuario.dart';

class UsuarioRepository {
  Future<int> inserir(Usuario usuario) async {
    final db = await DatabaseHelper.database;

    return await db.insert('usuario', usuario.toMap());
  }

  Future<List<Usuario>> listarTodos() async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query('usuario');

    return maps.map((map) => Usuario.fromMap(map)).toList();
  }

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
