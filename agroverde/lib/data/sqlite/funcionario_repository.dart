import '../../domain/entities/funcionario.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/api_json.dart';

/// Responsável pelas operações de funcionários — via API (/api/Funcionario).
///
/// O usuário vem do token JWT e a propriedade é validada pela API: o app nunca
/// consegue ler ou alterar funcionários de propriedades de outros usuários.
/// Nomes e assinaturas públicas são os mesmos da versão SQLite.
///
/// Datas: o app usa dd/MM/aaaa (ou aaaa-MM-dd, vindo do desligamento); a API usa
/// aaaa-MM-dd. A conversão é feita aqui, nas duas direções.
class FuncionarioRepository {
  static String? _dataParaApi(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;

    final texto = valor.trim();

    if (texto.contains('-')) {
      return texto.length >= 10 ? texto.substring(0, 10) : texto;
    }

    final partes = texto.split('/');

    if (partes.length != 3 || partes[2].length != 4) {
      throw Exception('Data inválida. Use o formato dd/MM/aaaa.');
    }

    return '${partes[2]}-${partes[1].padLeft(2, '0')}-${partes[0].padLeft(2, '0')}';
  }

  static String? _dataDaApi(dynamic valor) {
    if (valor is! String || valor.length < 10) return null;

    final partes = valor.substring(0, 10).split('-');

    if (partes.length != 3) return null;

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  static String? _textoOuNulo(String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;

    return valor.trim();
  }

  static Funcionario _doJson(Map<String, dynamic> json) {
    return Funcionario(
      id: jsonIntOuNulo(json['id']),
      pessoaId: jsonInt(json['pessoaId']),
      propriedadeId: jsonInt(json['propriedadeId']),
      cargo: (json['cargo'] ?? '') as String,
      salario: jsonDoubleOuNulo(json['salario']),
      dataContratacao: _dataDaApi(json['dataContratacao']),
      dataDesligamento: _dataDaApi(json['dataDesligamento']),
      status: (json['status'] ?? 'Ativo') as String,
      observacao: json['observacao'] as String?,
      nome: json['nome'] as String?,
      cpf: json['cpf'] as String?,
      telefone: json['telefone'] as String?,
    );
  }

  static Map<String, dynamic> _paraJson(Funcionario funcionario) {
    return {
      'propriedadeId': funcionario.propriedadeId,
      'nome': funcionario.nome,
      'cpf': _textoOuNulo(funcionario.cpf),
      'telefone': _textoOuNulo(funcionario.telefone),
      'cargo': funcionario.cargo,
      'salario': funcionario.salario,
      'dataContratacao': _dataParaApi(funcionario.dataContratacao),
      'dataDesligamento': _dataParaApi(funcionario.dataDesligamento),
      'status': funcionario.status,
      'observacao': _textoOuNulo(funcionario.observacao),
    };
  }

  static List<Funcionario> _lista(dynamic data) {
    return jsonLista(data).map(_doJson).toList();
  }

  /// Insere um novo funcionário (e a pessoa, se necessário) e devolve o id.
  Future<int> inserir(Funcionario funcionario) async {
    final data = await ApiClient.post(
      '/api/Funcionario',
      corpo: _paraJson(funcionario),
    );

    return jsonInt((data as Map)['id']);
  }

  /// Atualiza os dados do funcionário (e da pessoa vinculada).
  Future<int> atualizar(Funcionario funcionario) async {
    await ApiClient.put(
      '/api/Funcionario/${funcionario.id}',
      corpo: _paraJson(funcionario),
    );

    return 1;
  }

  /// Registra o desligamento do funcionário.
  Future<void> desligar({
    required int id,
    required String dataDesligamento,
    String? observacao,
  }) async {
    await ApiClient.post(
      '/api/Funcionario/$id/desligar',
      corpo: {
        'dataDesligamento': _dataParaApi(dataDesligamento),
        'observacao': observacao,
      },
    );
  }

  /// Remove um funcionário.
  Future<int> excluir(int id) async {
    await ApiClient.delete('/api/Funcionario/$id');

    return 1;
  }

  /// Busca um funcionário pelo ID (null se não existir ou não for do usuário).
  Future<Funcionario?> buscarPorId(int id) async {
    try {
      final data = await ApiClient.get('/api/Funcionario/$id');

      if (data is! Map) return null;

      return _doJson(Map<String, dynamic>.from(data));
    } on ApiException catch (erro) {
      if (erro.naoEncontrado) return null;

      rethrow;
    }
  }

  /// Lista os funcionários da propriedade.
  Future<List<Funcionario>> listarPorPropriedadeId(int propriedadeId) async {
    final data = await ApiClient.get(
      '/api/Funcionario',
      query: {'propriedadeId': '$propriedadeId'},
    );

    return _lista(data);
  }

  /// Lista apenas funcionários ativos.
  Future<List<Funcionario>> listarAtivosPorPropriedadeId(
    int propriedadeId,
  ) async {
    final data = await ApiClient.get(
      '/api/Funcionario',
      query: {'propriedadeId': '$propriedadeId', 'somenteAtivos': 'true'},
    );

    return _lista(data);
  }

  /// Lista os funcionários de todas as propriedades do usuário logado.
  Future<List<Funcionario>> listarTodos() async {
    final data = await ApiClient.get('/api/Funcionario');

    return _lista(data);
  }

  /// Verifica se a pessoa já está vinculada à propriedade.
  Future<bool> existeFuncionarioParaPessoa(
    int pessoaId,
    int propriedadeId,
  ) async {
    final lista = await listarPorPropriedadeId(propriedadeId);

    return lista.any((funcionario) => funcionario.pessoaId == pessoaId);
  }
}
