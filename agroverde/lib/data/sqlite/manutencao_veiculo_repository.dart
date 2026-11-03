import '../../domain/entities/manutencao_veiculo.dart';
import '../api/api_client.dart';
import '../api/api_datas.dart';
import '../api/api_exception.dart';
import '../api/api_json.dart';

/// Manutenções dos veículos — via API (/api/Veiculo/...).
///
/// A API grava a manutenção e a despesa no Financeiro na mesma
/// transação; alterar ou excluir a manutenção ajusta a despesa.
class ManutencaoVeiculoRepository {
  static const String _caminho = '/api/Veiculo';

  static ManutencaoVeiculo _doJson(Map<String, dynamic> json) {
    return ManutencaoVeiculo(
      id: jsonIntOuNulo(json['id']),
      veiculoId: jsonInt(json['veiculoId']),
      data: (json['data'] ?? '') as String,
      tipo: (json['tipo'] ?? '') as String,
      descricao: (json['descricao'] ?? '') as String,
      valor: jsonDouble(json['valor']),
      observacao: (json['observacao'] ?? '') as String,
    );
  }

  static Map<String, dynamic> _paraJson(ManutencaoVeiculo item) {
    return {
      'veiculoId': item.veiculoId,
      'data': dataParaApi(item.data, campo: 'data da manutenção'),
      'tipo': item.tipo.trim(),
      'descricao': textoOuNulo(item.descricao),
      'valor': item.valor,
      'observacao': textoOuNulo(item.observacao),
    };
  }

  Future<int> inserir(ManutencaoVeiculo manutencao) async {
    final data = await ApiClient.post(
      '$_caminho/manutencoes',
      corpo: _paraJson(manutencao),
    );

    return jsonInt((data as Map)['id']);
  }

  Future<int> atualizar(ManutencaoVeiculo manutencao) async {
    await ApiClient.put(
      '$_caminho/manutencoes/${manutencao.id}',
      corpo: _paraJson(manutencao),
    );

    return 1;
  }

  /// Exclui a manutenção e a despesa gerada por ela.
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/manutencoes/$id');

    return 1;
  }

  Future<ManutencaoVeiculo?> buscarPorId(int id) async {
    // A API não expõe a busca individual; não há uso dessa busca nas telas.
    throw ApiException('Busca de manutenção por ID não disponível.');
  }

  /// Manutenções do veículo (mais recentes primeiro).
  Future<List<ManutencaoVeiculo>> listarPorVeiculoId(int veiculoId) async {
    final data = await ApiClient.get('$_caminho/$veiculoId/manutencoes');

    return jsonLista(data).map(_doJson).toList();
  }

  Future<double> totalGastoVeiculo(int veiculoId) async {
    final lista = await listarPorVeiculoId(veiculoId);

    return lista.fold<double>(0, (total, m) => total + m.valor);
  }

  Future<int> quantidadeManutencoes(int veiculoId) async {
    return (await listarPorVeiculoId(veiculoId)).length;
  }
}
