import '../../data/sqlite/funcionario_repository.dart';
import '../../data/sqlite/financeiro_repository.dart';

import '../entities/funcionario.dart';
import '../entities/lancamento_financeiro.dart';

/// Responsável pelas regras de negócio dos funcionários.
class FuncionarioService {
  final FuncionarioRepository _funcionarioRepository = FuncionarioRepository();

  final FinanceiroRepository _financeiroRepository = FinanceiroRepository();

  /// Salva ou atualiza um funcionário.
  Future<int> salvar(Funcionario funcionario) async {
    _validarFuncionario(funcionario);

    if (funcionario.id == null) {
      final existe = await _funcionarioRepository.existeFuncionarioParaPessoa(
        funcionario.pessoaId,
        funcionario.propriedadeId,
      );

      if (existe) {
        throw Exception(
          'Essa pessoa já está cadastrada como funcionário nesta propriedade.',
        );
      }

      return await _funcionarioRepository.inserir(funcionario);
    }

    return await _funcionarioRepository.atualizar(funcionario);
  }

  /// Registra o desligamento do funcionário.
  Future<void> desligarFuncionario({
    required Funcionario funcionario,
    required String dataDesligamento,
    String? observacao,
  }) async {
    funcionario.status = 'Desligado';
    funcionario.dataDesligamento = _converterDataBrParaBanco(dataDesligamento);
    funcionario.observacao = observacao ?? funcionario.observacao;

    _validarFuncionario(funcionario);

    await _funcionarioRepository.atualizar(funcionario);
  }

  /// Lança a folha de pagamento no financeiro.
  Future<void> registrarFolhaPagamento({
    required Funcionario funcionario,
    required String data,
    int? safraId,
  }) async {
    if (funcionario.salario == null || funcionario.salario! <= 0) {
      throw Exception('O funcionário não possui salário válido.');
    }

    if (data.trim().isEmpty) {
      throw Exception('Informe a data do lançamento da folha.');
    }

    final dataBanco = _converterDataBrParaBanco(data);

    final lancamento = LancamentoFinanceiro(
      propriedadeId: funcionario.propriedadeId,
      descricao: 'Folha de pagamento - ${funcionario.cargo}',
      valor: funcionario.salario!,
      tipo: 'despesa',
      data: dataBanco,
      safraId: safraId,
    );

    await _financeiroRepository.inserir(lancamento);
  }

  /// Lista os funcionários da propriedade.
  Future<List<Funcionario>> listarPorPropriedadeId(int propriedadeId) async {
    if (propriedadeId <= 0) {
      throw Exception('Propriedade inválida.');
    }

    return await _funcionarioRepository.listarPorPropriedadeId(propriedadeId);
  }

  /// Lista apenas funcionários ativos.
  Future<List<Funcionario>> listarAtivosPorPropriedadeId(
    int propriedadeId,
  ) async {
    if (propriedadeId <= 0) {
      throw Exception('Propriedade inválida.');
    }

    return await _funcionarioRepository.listarAtivosPorPropriedadeId(
      propriedadeId,
    );
  }

  /// Busca um funcionário pelo ID.
  Future<Funcionario?> buscarPorId(int id) async {
    if (id <= 0) {
      throw Exception('Funcionário inválido.');
    }

    return await _funcionarioRepository.buscarPorId(id);
  }

  /// Remove um funcionário.
  Future<void> excluir(int id) async {
    if (id <= 0) {
      throw Exception('Funcionário inválido.');
    }

    await _funcionarioRepository.excluir(id);
  }

  /// Valida os dados obrigatórios do funcionário.
  void _validarFuncionario(Funcionario funcionario) {
    if (funcionario.pessoaId <= 0) {
      throw Exception('Pessoa inválida.');
    }

    if (funcionario.propriedadeId <= 0) {
      throw Exception('Propriedade inválida.');
    }

    if (funcionario.cargo.trim().isEmpty) {
      throw Exception('O cargo é obrigatório.');
    }

    if (funcionario.salario != null && funcionario.salario! < 0) {
      throw Exception('O salário não pode ser negativo.');
    }

    if (funcionario.status.trim().isEmpty) {
      throw Exception('O status é obrigatório.');
    }

    if (funcionario.status == 'Desligado' &&
        (funcionario.dataDesligamento == null ||
            funcionario.dataDesligamento!.trim().isEmpty)) {
      throw Exception('Informe a data de desligamento do funcionário.');
    }
  }

  /// Converte datas para o padrão do banco.
  String _converterDataBrParaBanco(String data) {
    final valor = data.trim();

    if (valor.contains('-')) {
      return valor;
    }

    final partes = valor.split('/');

    if (partes.length != 3) {
      throw Exception('Data inválida. Use o formato dd/MM/aaaa.');
    }

    final dia = partes[0].padLeft(2, '0');
    final mes = partes[1].padLeft(2, '0');
    final ano = partes[2];

    if (ano.length != 4) {
      throw Exception('Ano inválido. Use quatro dígitos.');
    }

    return '$ano-$mes-$dia';
  }
}
