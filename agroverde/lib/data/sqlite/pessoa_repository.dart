import 'database_helper.dart';
import '../../domain/entities/pessoa.dart';
import '../api/api_client.dart';
import '../api/api_json.dart';

/// Responsável pelas operações de pessoas.
///
/// - Perfil do usuário (usuarioId > 0): via API (/api/Perfil). O usuário é
///   sempre o do token JWT; o app nunca envia o id do usuário.
/// - Pessoas operacionais de Funcionários (usuarioId == 0): continuam no SQLite.
class PessoaRepository {
  static bool _ehPerfil(Pessoa pessoa) => (pessoa.usuarioId ?? 0) > 0;

  static Pessoa _perfilDoJson(Map<String, dynamic> json) {
    return Pessoa(
      id: jsonIntOuNulo(json['id']),
      usuarioId: jsonIntOuNulo(json['usuarioId']),
      nome: json['nome'] as String?,
      cpf: json['cpf'] as String?,
      telefone: json['telefone'] as String?,
      cep: json['cep'] as String?,
      rua: json['rua'] as String?,
      numero: json['numero'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
    );
  }

  static Map<String, dynamic> _perfilParaJson(Pessoa p) {
    return {
      'nome': p.nome,
      'cpf': p.cpf,
      'telefone': p.telefone,
      'cep': p.cep,
      'rua': p.rua,
      'numero': p.numero,
      'bairro': p.bairro,
      'cidade': p.cidade,
      'estado': p.estado,
    };
  }

  /// PUT cria o perfil na primeira vez e atualiza nas seguintes.
  static Future<int> _salvarPerfil(Pessoa pessoa) async {
    final data = await ApiClient.put(
      '/api/Perfil',
      corpo: _perfilParaJson(pessoa),
    );

    return jsonInt((data as Map)['id']);
  }

  /// Insere uma nova pessoa.
  Future<int> inserir(Pessoa pessoa) async {
    if (_ehPerfil(pessoa)) {
      return await _salvarPerfil(pessoa);
    }

    final db = await DatabaseHelper.database;

    return await db.insert('pessoa', pessoa.toMap());
  }

  /// Busca a pessoa vinculada ao usuário.
  Future<Pessoa?> buscarPorUsuarioId(int usuarioId) async {
    if (usuarioId > 0) {
      // Perfil: a API usa o usuário do token. data == null => ainda sem perfil.
      final data = await ApiClient.get('/api/Perfil');

      if (data is! Map) {
        return null;
      }

      return _perfilDoJson(Map<String, dynamic>.from(data));
    }

    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'pessoa',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Pessoa.fromMap(resultado.first);
  }

  /// Busca uma pessoa pelo ID.
  Future<Pessoa?> buscarPorId(int id) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'pessoa',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Pessoa.fromMap(resultado.first);
  }

  /// Busca pessoa operacional pelo CPF.
  Future<Pessoa?> buscarPorCpfOperacional(String cpf) async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'pessoa',
      where: 'cpf = ? AND usuario_id = ?',
      whereArgs: [cpf, 0],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Pessoa.fromMap(resultado.first);
  }

  /// Atualiza os dados de uma pessoa.
  Future<int> atualizar(Pessoa pessoa) async {
    if (_ehPerfil(pessoa)) {
      await _salvarPerfil(pessoa);

      return 1;
    }

    final db = await DatabaseHelper.database;

    return await db.update(
      'pessoa',
      pessoa.toMap(),
      where: 'id = ?',
      whereArgs: [pessoa.id],
    );
  }

  /// Remove uma pessoa.
  Future<int> excluir(int id) async {
    final db = await DatabaseHelper.database;

    return await db.delete('pessoa', where: 'id = ?', whereArgs: [id]);
  }

  /// Lista todas as pessoas cadastradas.
  Future<List<Pessoa>> listarTodos() async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query('pessoa', orderBy: 'nome ASC');

    return resultado.map((map) => Pessoa.fromMap(map)).toList();
  }

  /// Lista pessoas operacionais.
  Future<List<Pessoa>> listarOperacionais() async {
    final db = await DatabaseHelper.database;

    final resultado = await db.query(
      'pessoa',
      where: 'usuario_id = ?',
      whereArgs: [0],
      orderBy: 'nome ASC',
    );

    return resultado.map((map) => Pessoa.fromMap(map)).toList();
  }
}
