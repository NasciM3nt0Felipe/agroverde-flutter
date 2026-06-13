import '../../data/sqlite/talhao_repository.dart';
import '../entities/talhao.dart';

class TalhaoService {
  final TalhaoRepository _repository = TalhaoRepository();

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
