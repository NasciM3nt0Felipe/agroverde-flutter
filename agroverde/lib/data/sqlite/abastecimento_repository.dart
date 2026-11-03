import '../../domain/entities/abastecimento.dart';
import '../api/api_client.dart';
import '../api/api_datas.dart';
import '../api/api_exception.dart';
import '../api/api_json.dart';

/// Abastecimentos dos veículos — via API (/api/Veiculo/...).
///
/// A API grava o abastecimento e a despesa no Financeiro na mesma
/// transação; alterar ou excluir o abastecimento ajusta a despesa.
class AbastecimentoRepository {
  static const String _caminho = '/api/Veiculo';

  static Abastecimento _doJson(Map<String, dynamic> json) {
    return Abastecimento(
      id: jsonIntOuNulo(json['id']),
      veiculoId: jsonInt(json['veiculoId']),
      data: (json['data'] ?? '') as String,
      litros: jsonDouble(json['litros']),
      valorTotal: jsonDouble(json['valorTotal']),
      observacao: (json['observacao'] ?? '') as String,
    );
  }

  static Map<String, dynamic> _paraJson(Abastecimento item) {
    return {
      'veiculoId': item.veiculoId,
      'data': dataParaApi(item.data, campo: 'data do abastecimento'),
      'litros': item.litros,
      'valorTotal': item.valorTotal,
      'observacao': textoOuNulo(item.observacao),
    };
  }

  Future<int> inserir(Abastecimento abastecimento) async {
    final data = await ApiClient.post(
      '$_caminho/abastecimentos',
      corpo: _paraJson(abastecimento),
    );

    return jsonInt((data as Map)['id']);
  }

  Future<int> atualizar(Abastecimento abastecimento) async {
    await ApiClient.put(
      '$_caminho/abastecimentos/${abastecimento.id}',
      corpo: _paraJson(abastecimento),
    );

    return 1;
  }

  /// Exclui o abastecimento e a despesa gerada por ele.
  Future<int> excluir(int id) async {
    await ApiClient.delete('$_caminho/abastecimentos/$id');

    return 1;
  }

  Future<Abastecimento?> buscarPorId(int id) async {
    // A API não expõe a busca individual; não há uso dessa busca nas telas.
    throw ApiException('Busca de abastecimento por ID não disponível.');
  }

  /// Abastecimentos do veículo (mais recentes primeiro).
  Future<List<Abastecimento>> listarPorVeiculoId(int veiculoId) async {
    final data = await ApiClient.get('$_caminho/$veiculoId/abastecimentos');

    return jsonLista(data).map(_doJson).toList();
  }

  Future<double> totalGastoVeiculo(int veiculoId) async {
    final lista = await listarPorVeiculoId(veiculoId);

    return lista.fold<double>(0, (total, a) => total + a.valorTotal);
  }

  Future<double> totalLitrosVeiculo(int veiculoId) async {
    final lista = await listarPorVeiculoId(veiculoId);

    return lista.fold<double>(0, (total, a) => total + a.litros);
  }
}
