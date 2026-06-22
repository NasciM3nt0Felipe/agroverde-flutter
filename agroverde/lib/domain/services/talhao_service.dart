import '../../data/sqlite/propriedade_repository.dart';
import '../../data/sqlite/talhao_repository.dart';
import '../entities/talhao.dart';

class TalhaoService {
  final TalhaoRepository _repository = TalhaoRepository();
  final PropriedadeRepository _propriedadeRepository = PropriedadeRepository();

  /// Percentual máximo da área da propriedade que pode ser usado por talhões.
  ///
  /// Exemplo:
  /// Propriedade com 100 ha -> máximo para talhões = 90 ha.
  /// Os 10% restantes ficam reservados para casa, galpão, estrada, curral etc.
  static const double percentualAreaCultivavel = 0.90;

  Future<List<Talhao>> listarPorPropriedadeId(int propriedadeId) async {
    return await _repository.listarPorPropriedadeId(propriedadeId);
  }

  /// Salva um talhão novo ou atualiza um existente.
  ///
  /// Retorno:
  /// - null: salvou com sucesso.
  /// - String: houve erro de validação/regra de negócio.
  Future<String?> salvar(Talhao talhao) async {
    final nome = talhao.nome.trim();

    if (nome.isEmpty) {
      return 'Informe o nome do talhão.';
    }

    if (talhao.area <= 0) {
      return 'Informe uma área válida.';
    }

    final propriedade = await _propriedadeRepository.buscarPorId(
      talhao.propriedadeId,
    );

    if (propriedade == null) {
      return 'Propriedade não encontrada.';
    }

    final talhoes = await _repository.listarPorPropriedadeId(
      talhao.propriedadeId,
    );

    double areaJaUtilizada = 0;

    for (final item in talhoes) {
      final mesmoTalhao = talhao.id != null && item.id == talhao.id;

      if (mesmoTalhao) {
        continue;
      }

      areaJaUtilizada += item.area;
    }

    final double areaMaximaCultivavel =
        propriedade.areaTotal * percentualAreaCultivavel;

    final double areaDisponivel = areaMaximaCultivavel - areaJaUtilizada;

    final double areaDisponivelTratada = areaDisponivel < 0
        ? 0.0
        : areaDisponivel;

    final double areaTotalAposSalvar = areaJaUtilizada + talhao.area;

    if (areaTotalAposSalvar > areaMaximaCultivavel) {
      return 'Área excedida. A propriedade mantém 10% como reserva técnica. '
          'Área máxima para talhões: ${_formatarArea(areaMaximaCultivavel)} ha. '
          'Disponível para novos talhões: ${_formatarArea(areaDisponivelTratada)} ha.';
    }

    if (talhao.id == null) {
      await _repository.inserir(talhao);
    } else {
      await _repository.atualizar(talhao);
    }

    return null;
  }

  Future<void> excluir(int id) async {
    await _repository.excluir(id);
  }

  String _formatarArea(double valor) {
    if (valor % 1 == 0) {
      return valor.toStringAsFixed(0);
    }

    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }
}
