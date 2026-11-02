import '../api/api_client.dart';
import 'database_helper.dart';
import '../../domain/entities/usuario.dart';

/// Repositório responsável pelas operações de usuários.
///
/// Durante a migração, mantemos os métodos antigos do SQLite
/// para preservar a compatibilidade com outras partes do Flutter.
///
/// Os novos métodos autenticar() e cadastrar() utilizam
/// a API .NET 8 do AgroVerde.
class UsuarioRepository {
  // ============================================================
  // MÉTODOS ANTIGOS — SQLITE
  // ============================================================

  /// Insere um usuário no banco SQLite local.
  ///
  /// Mantido temporariamente para compatibilidade.
  Future<int> inserir(Usuario usuario) async {
    final db = await DatabaseHelper.database;

    return await db.insert('usuario', usuario.toMap());
  }

  /// Lista todos os usuários cadastrados no SQLite local.
  Future<List<Usuario>> listarTodos() async {
    final db = await DatabaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query('usuario');

    return maps.map((map) => Usuario.fromMap(map)).toList();
  }

  /// Busca um usuário pelo e-mail no SQLite local.
  ///
  /// Atenção: este método NÃO consulta a API.
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

  /// Atualiza a senha no SQLite local.
  ///
  /// Este método pertence à implementação antiga.
  /// A troca de senha deverá ser migrada para a API.
  Future<int> atualizarSenha(int usuarioId, String novaSenhaHash) async {
    final db = await DatabaseHelper.database;

    return await db.update(
      'usuario',
      {'senha': novaSenhaHash},
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  // ============================================================
  // NOVOS MÉTODOS — API .NET 8
  // ============================================================

  /// Autentica o usuário utilizando a API .NET 8.
  ///
  /// A API verifica as credenciais e devolve:
  /// - Token JWT;
  /// - ID do usuário;
  /// - Nome;
  /// - E-mail.
  ///
  /// A senha não é devolvida pela API.
  Future<Usuario> autenticar({
    required String email,
    required String senha,
  }) async {
    // Envia as credenciais para a API.
    //
    // autenticado: false porque o usuário ainda
    // não possui um token JWT.
    final resposta = await ApiClient.post(
      '/api/Auth/login',
      autenticado: false,
      corpo: {'email': email.trim(), 'senha': senha},
    );

    // Converte os dados retornados pela API
    // para um mapa do Dart.
    final dados = Map<String, dynamic>.from(resposta as Map);

    // Obtém o token JWT.
    final token = dados['token'] as String?;

    // Impede continuar se a API não devolver o token.
    if (token == null || token.isEmpty) {
      throw Exception('A API não retornou o token de autenticação.');
    }

    // Recupera os dados do usuário autenticado.
    final dadosUsuario = Map<String, dynamic>.from(dados['usuario'] as Map);

    // Constrói o objeto Usuario utilizado pelo Flutter.
    //
    // A senha fica vazia porque a API não a devolve.
    final usuario = Usuario(
      id: dadosUsuario['id'] as int,
      nome: dadosUsuario['nome'] as String,
      email: dadosUsuario['email'] as String,
      senha: '',
    );

    // Armazena o JWT no ApiClient.
    //
    // Nas próximas requisições autenticadas,
    // ele será enviado no cabeçalho:
    //
    // Authorization: Bearer TOKEN_JWT
    ApiClient.definirToken(token);

    // Retorna o usuário para a tela de login.
    return usuario;
  }

  /// Cadastra um novo usuário utilizando a API .NET 8.
  ///
  /// Endpoint:
  /// POST /api/Auth/register
  ///
  /// A API recebe nome, e-mail e senha.
  /// O armazenamento seguro da senha fica
  /// sob responsabilidade do backend.
  Future<void> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    // Envia os dados do cadastro para a API.
    //
    // Não calculamos SHA-256 no Flutter.
    // A senha é enviada à API para que o backend
    // aplique sua própria regra de armazenamento.
    //
    // autenticado: false porque ainda não existe
    // uma sessão autenticada.
    await ApiClient.post(
      '/api/Auth/register',
      autenticado: false,
      corpo: {'nome': nome.trim(), 'email': email.trim(), 'senha': senha},
    );

    // Se a API retornar um erro, o ApiClient
    // lançará uma ApiException.
    //
    // Se a execução chegar aqui, a API confirmou
    // que a operação foi concluída com sucesso.
  }
}
