import '../../data/sqlite/armazenamento_grao_repository.dart';
import '../../data/sqlite/colheita_repository.dart';
import '../../data/sqlite/financeiro_repository.dart';
import '../../data/sqlite/safra_repository.dart';
import '../../data/sqlite/venda_grao_repository.dart';
import '../entities/armazenamento_grao.dart';
import '../entities/colheita.dart';
import '../entities/lancamento_financeiro.dart';
import '../entities/safra.dart';
import '../entities/venda_grao.dart';

class ColheitaService {
  final ColheitaRepository _colheitaRepository = ColheitaRepository();

  final ArmazenamentoGraoRepository _armazenamentoRepository =
      ArmazenamentoGraoRepository();

  final VendaGraoRepository _vendaRepository = VendaGraoRepository();

  final FinanceiroRepository _financeiroRepository = FinanceiroRepository();

  final SafraRepository _safraRepository = SafraRepository();

  Future<void> registrarColheita({
    required int safraId,
    required int propriedadeId,
    required String produto,
    required String dataColheita,
    required double quantidadeProduzida,
    required String unidade,
    String? observacao,
  }) async {
    if (produto.trim().isEmpty) {
      throw Exception('Informe o produto colhido.');
    }

    if (quantidadeProduzida <= 0) {
      throw Exception('A quantidade produzida deve ser maior que zero.');
    }

    final safra = await _safraRepository.buscarPorId(safraId);

    if (safra == null) {
      throw Exception('Safra não encontrada.');
    }

    if (safra.status == 'Planejada') {
      throw Exception(
        'Não é possível colher uma safra sem plantio registrado.',
      );
    }

    if (safra.status == 'Colhida') {
      throw Exception('Esta safra já foi colhida.');
    }

    final colheita = Colheita(
      safraId: safraId,
      propriedadeId: propriedadeId,
      dataColheita: dataColheita,
      quantidadeProduzida: quantidadeProduzida,
      unidade: unidade,
      observacao: observacao,
    );

    final colheitaId = await _colheitaRepository.inserir(colheita);

    final armazenamento = ArmazenamentoGrao(
      colheitaId: colheitaId,
      propriedadeId: propriedadeId,
      produto: produto.trim(),
      quantidadeTotal: quantidadeProduzida,
      quantidadeDisponivel: quantidadeProduzida,
      unidade: unidade,
      status: 'Disponível',
    );

    await _armazenamentoRepository.inserir(armazenamento);

    await _safraRepository.atualizar(
      Safra(
        id: safra.id,
        talhaoId: safra.talhaoId,
        nome: safra.nome,
        cultura: safra.cultura,
        variedade: safra.variedade,
        dataPlantio: safra.dataPlantio,
        dataColheitaPrevista: safra.dataColheitaPrevista,
        dataColheitaReal: dataColheita,
        producaoEstimada: safra.producaoEstimada,
        producaoObtida: quantidadeProduzida,
        status: 'Colhida',
        observacao: safra.observacao,
      ),
    );
  }

  Future<void> registrarVenda({
    required int armazenamentoId,
    required int propriedadeId,
    required String dataVenda,
    required double quantidadeVendida,
    required double valorUnitario,
    required String unidade,
    String? comprador,
    String? observacao,
  }) async {
    if (quantidadeVendida <= 0) {
      throw Exception('A quantidade vendida deve ser maior que zero.');
    }

    if (valorUnitario <= 0) {
      throw Exception('O valor unitário deve ser maior que zero.');
    }

    final armazenamento = await _armazenamentoRepository.buscarPorId(
      armazenamentoId,
    );

    if (armazenamento == null) {
      throw Exception('Armazenamento não encontrado.');
    }

    if (quantidadeVendida > armazenamento.quantidadeDisponivel) {
      throw Exception('Quantidade vendida maior que a disponível.');
    }

    final valorTotal = quantidadeVendida * valorUnitario;

    final venda = VendaGrao(
      armazenamentoId: armazenamentoId,
      propriedadeId: propriedadeId,
      dataVenda: dataVenda,
      comprador: comprador,
      quantidadeVendida: quantidadeVendida,
      valorUnitario: valorUnitario,
      valorTotal: valorTotal,
      unidade: unidade,
      observacao: observacao,
    );

    await _vendaRepository.inserir(venda);

    await _financeiroRepository.inserir(
      LancamentoFinanceiro(
        propriedadeId: propriedadeId,
        descricao: 'Venda de ${armazenamento.produto}',
        valor: valorTotal,
        tipo: 'receita',
        data: dataVenda,
        safraId: null,
      ),
    );

    final novaQuantidade =
        armazenamento.quantidadeDisponivel - quantidadeVendida;

    final armazenamentoAtualizado = ArmazenamentoGrao(
      id: armazenamento.id,
      colheitaId: armazenamento.colheitaId,
      propriedadeId: armazenamento.propriedadeId,
      produto: armazenamento.produto,
      quantidadeTotal: armazenamento.quantidadeTotal,
      quantidadeDisponivel: novaQuantidade,
      unidade: armazenamento.unidade,
      status: novaQuantidade <= 0 ? 'Vendido' : 'Disponível',
    );

    await _armazenamentoRepository.atualizar(armazenamentoAtualizado);
  }

  Future<List<Colheita>> listarColheitas(int propriedadeId) {
    return _colheitaRepository.listarPorPropriedade(propriedadeId);
  }

  Future<List<ArmazenamentoGrao>> listarArmazenamentos(int propriedadeId) {
    return _armazenamentoRepository.listarPorPropriedade(propriedadeId);
  }

  Future<List<VendaGrao>> listarVendas(int propriedadeId) {
    return _vendaRepository.listarPorPropriedade(propriedadeId);
  }
}
