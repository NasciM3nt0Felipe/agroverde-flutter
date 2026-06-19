import '../../data/sqlite/propriedade_repository.dart';
import '../../data/sqlite/talhao_repository.dart';
import '../entities/talhao.dart';

class TalhaoService {
  final TalhaoRepository _repository = TalhaoRepository();
  final PropriedadeRepository _propriedadeRepository = PropriedadeRepository();

  Future<List<Talhao>> listarPorPropriedadeId(int propriedadeId) async {
    return await _repository.listarPorPropriedadeId(propriedadeId);
  }

  Future<void> salvar(Talhao talhao) async {
    if (talhao.nome.trim().isEmpty) {
      throw Exception('Informe o nome do talhão.');
    }

    if (talhao.area <= 0) {
      throw Exception('Informe uma área válida.');
    }

    final propriedade = await _propriedadeRepository.buscarPorId(
      talhao.propriedadeId,
    );

    if (propriedade == null) {
      throw Exception('Propriedade não encontrada.');
    }

    final talhoes = await _repository.listarPorPropriedadeId(
      talhao.propriedadeId,
    );

    double areaJaUtilizada = 0;

    for (final item in talhoes) {
      if (talhao.id != null && item.id == talhao.id) {
        continue;
      }

      areaJaUtilizada += item.area;
    }

    final areaTotalAposSalvar = areaJaUtilizada + talhao.area;

    if (areaTotalAposSalvar > propriedade.areaTotal) {
      final areaDisponivel = propriedade.areaTotal - areaJaUtilizada;

      throw Exception(
        'Área excedida. Disponível para novos talhões: '
        '${areaDisponivel.toStringAsFixed(2)} ha.',
      );
    }

    if (talhao.id == null) {
      await _repository.inserir(talhao);
    } else {
      await _repository.atualizar(talhao);
    }
  }

  Future<void> excluir(int id) async {
    await _repository.excluir(id);
  }
}
