import '../../domain/entities/veiculo.dart';
import '../api/api_client.dart';
import '../api/api_datas.dart';
import '../api/api_exception.dart';
import '../api/api_json.dart';

/// Veículos da propriedade — via API (/api/Veiculo).
///
/// O usuário vem do token JWT e a API só aceita veículos das propriedades
/// dele. Nomes e assinaturas públicas são os mesmos da versão SQLite.
class VeiculoRepository {
  static const String _caminho = '/api/Veiculo';

  // Tipos do app <-> enum TipoVeiculo da API.
  static const Map<String, int> _tipoParaApi = {
    'Trator': 1,
    'Colheitadeira': 2,
    'Pulverizador': 3,
    'Caminhonete': 4,
    'Caminhão': 5,
    'Implemento': 6,
    'Outro': 7,
  };

  // Status do app <-> enum StatusVeiculo da API.
  static const Map<String, int> _statusParaApi = {
    'Ativo': 1,
    'Manutenção': 2,
    'Inativo': 3,
    'Vendido': 4,
  };

  static String _chavePorValor(Map<String, int> mapa, dynamic valor, String padrao) {
    final numero = jsonIntOuNulo(valor);

    for (final entrada in mapa.entries) {
      if (entrada.value == numero) return entrada.key;
    }

    return padrao;
  }

  static Veiculo _doJson(Map<String, dynamic> json) {
    return Veiculo(
      id: jsonIntOuNulo(json['id']),
      propriedadeId: jsonInt(json['propriedadeId']),
      nome: (json['nome'] ?? '') as String,
      tipo: _chavePorValor(_tipoParaApi, json['tipo'], 'Outro'),
      marca: (json['marca'] ?? '') as String,
      modelo: (json['modelo'] ?? '') as String,
      ano: jsonInt(json['anoFabricacao']),
      placa: (json['placaOuChassi'] ?? '') as String,
      horimetroOdometroAtual: jsonDouble(json['horimetroAtual']),
      status: _chavePorValor(_statusParaApi, json['status'], 'Ativo'),
      valorVenda: jsonDouble(json['valorVenda']),
      dataVenda: json['dataVenda'] == null ? null : dataDaApi(json['dataVenda']),
      observacao: (json['observacoes'] ?? '') as String,
    );
  }

  static Map<String, dynamic> _paraJson(Veiculo veiculo) {
    return {
      'propriedadeId': veiculo.propriedadeId,
      'nome': veiculo.nome.trim(),
      'tipo': _tipoParaApi[veiculo.tipo] ?? 7,
      'marca': textoOuNulo(veiculo.marca),
      'modelo': textoOuNulo(veiculo.modelo),
      'anoFabricacao': veiculo.ano == 0 ? null : veiculo.ano,
      'placaOuChassi': textoOuNulo(veiculo.placa),
      'horimetroAtual': veiculo.horimetroOdometroAtual,
      'status': _statusParaApi[veiculo.status] ?? 1,
      'valorVenda': veiculo.valorVenda == 0 ? null : veiculo.valorVenda,
      'dataVenda': textoOuNulo(veiculo.dataVenda) == null
          ? null
          : dataParaApi(veiculo.dataVenda!, campo: 'data da venda'),
      'observacoes': textoOuNulo(veiculo.observacao),
    };
  }

  Future<int> inserir(Veiculo veiculo) async {
    final data = await ApiClient.post(_caminho, corpo: _paraJson(veiculo));

    return jsonInt((data as Map)['id']);
  }

  Future<int> atualizar(Veiculo veiculo) async {
    await ApiClient.put('$_caminho/${veiculo.id}', corpo: _paraJson(veiculo));

    return 1;
  }

  /// Exclui o veículo (a API recusa se houver abastecimentos ou manutenções).
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/$id');

    return 1;
  }

  Future<Veiculo?> buscarPorId(int id) async {
    try {
      final data = await ApiClient.get('$_caminho/$id');

      if (data is! Map) return null;

      return _doJson(Map<String, dynamic>.from(data));
    } on ApiException catch (erro) {
      if (erro.naoEncontrado) return null;

      rethrow;
    }
  }

  /// Veículos da propriedade, em ordem alfabética.
  Future<List<Veiculo>> listarPorPropriedadeId(int propriedadeId) async {
    final data = await ApiClient.get('$_caminho/propriedade/$propriedadeId');

    return jsonLista(data).map(_doJson).toList();
  }

  /// Veículos que não foram vendidos.
  Future<List<Veiculo>> listarAtivosPorPropriedadeId(int propriedadeId) async {
    final lista = await listarPorPropriedadeId(propriedadeId);

    return lista.where((v) => v.status != 'Vendido').toList();
  }

  Future<double> totalVendidoPorPropriedade(int propriedadeId) async {
    final lista = await listarPorPropriedadeId(propriedadeId);

    return lista.fold<double>(0, (total, v) => total + v.valorVenda);
  }

  Future<int> totalVeiculos(int propriedadeId) async {
    return (await listarPorPropriedadeId(propriedadeId)).length;
  }
}
