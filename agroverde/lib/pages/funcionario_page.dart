import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../domain/entities/pessoa.dart';
import '../domain/entities/funcionario.dart';
import '../domain/services/funcionario_service.dart';
import '../domain/services/sessao_service.dart';
import '../data/sqlite/pessoa_repository.dart';

class FuncionarioPage extends StatefulWidget {
  const FuncionarioPage({super.key});

  @override
  State<FuncionarioPage> createState() => _FuncionarioPageState();
}

class _FuncionarioPageState extends State<FuncionarioPage> {
  final PessoaRepository _pessoaRepository = PessoaRepository();
  final FuncionarioService _funcionarioService = FuncionarioService();

  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cargoController = TextEditingController();
  final _salarioController = TextEditingController();
  final _dataContratacaoController = TextEditingController();
  final _dataDesligamentoController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Pessoa> _pessoasOperacionais = [];
  List<Funcionario> _funcionarios = [];

  int? _funcionarioEditandoId;
  int? _pessoaOperacionalEditandoId;

  String _status = 'Ativo';
  String? _erroCpf;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _cargoController.dispose();
    _salarioController.dispose();
    _dataContratacaoController.dispose();
    _dataDesligamentoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  /// Carrega os funcionários da propriedade.
  Future<void> _carregarDados() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) return;

    setState(() => _carregando = true);

    final pessoas = await _pessoaRepository.listarOperacionais();

    final funcionarios = await _funcionarioService.listarPorPropriedadeId(
      propriedadeId,
    );

    if (!mounted) return;

    setState(() {
      _pessoasOperacionais = pessoas;
      _funcionarios = funcionarios;
      _carregando = false;
    });
  }

  /// Salva ou atualiza um funcionário.
  Future<void> _salvar() async {
    final propriedadeId = SessaoService.propriedadeId;

    setState(() {
      _erroCpf = null;
    });

    if (propriedadeId == null) {
      _mostrarMensagem('Selecione uma propriedade antes de continuar.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    try {
      int pessoaId;

      final cpfDigitado = _cpfController.text.trim();

      if (_funcionarioEditandoId == null) {
        if (cpfDigitado.isNotEmpty) {
          final pessoaExistente = await _pessoaRepository
              .buscarPorCpfOperacional(cpfDigitado);

          if (pessoaExistente != null) {
            setState(() {
              _erroCpf = 'CPF já cadastrado.';
            });

            _formKey.currentState!.validate();
            return;
          }
        }

        final pessoa = Pessoa(
          usuarioId: 0,
          nome: _nomeController.text.trim(),
          cpf: cpfDigitado,
          telefone: _telefoneController.text.trim(),
        );

        pessoaId = await _pessoaRepository.inserir(pessoa);
      } else {
        pessoaId = _pessoaOperacionalEditandoId!;

        final pessoaAtualizada = Pessoa(
          id: pessoaId,
          usuarioId: 0,
          nome: _nomeController.text.trim(),
          cpf: cpfDigitado,
          telefone: _telefoneController.text.trim(),
        );

        await _pessoaRepository.atualizar(pessoaAtualizada);
      }

      final salario = double.tryParse(
        _salarioController.text.replaceAll('.', '').replaceAll(',', '.'),
      );

      final funcionario = Funcionario(
        id: _funcionarioEditandoId,
        pessoaId: pessoaId,
        propriedadeId: propriedadeId,
        cargo: _cargoController.text.trim(),
        salario: salario,
        dataContratacao: _dataContratacaoController.text.trim(),
        dataDesligamento: _dataDesligamentoController.text.trim().isEmpty
            ? null
            : _dataDesligamentoController.text.trim(),
        status: _status,
        observacao: _observacaoController.text.trim(),
      );

      await _funcionarioService.salvar(funcionario);

      _mostrarMensagem('Funcionário salvo com sucesso.');
      _limparFormulario();
      await _carregarDados();
    } catch (e) {
      _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _selecionarData(TextEditingController controller) async {
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (dataSelecionada == null) return;

    final dia = dataSelecionada.day.toString().padLeft(2, '0');
    final mes = dataSelecionada.month.toString().padLeft(2, '0');
    final ano = dataSelecionada.year.toString();

    controller.text = '$dia/$mes/$ano';
  }

  /// Registra a folha de pagamento no financeiro.
  Future<void> _registrarFolha(Funcionario funcionario) async {
    final dataController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lançar folha de pagamento'),
          content: TextFormField(
            controller: dataController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Data do lançamento',
              hintText: 'dd/mm/aaaa',
              prefixIcon: Icon(Icons.calendar_month),
            ),
            onTap: () => _selecionarData(dataController),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                try {
                  await _funcionarioService.registrarFolhaPagamento(
                    funcionario: funcionario,
                    data: dataController.text.trim(),
                  );

                  if (!mounted) return;

                  Navigator.pop(context);
                  _mostrarMensagem('Folha lançada no financeiro.');
                } catch (e) {
                  _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
                }
              },
              child: const Text('Lançar'),
            ),
          ],
        );
      },
    );
  }

  /// Carrega os dados do funcionário para edição.
  void _editar(Funcionario funcionario) {
    final pessoa = _pessoasOperacionais.firstWhere(
      (p) => p.id == funcionario.pessoaId,
      orElse: () => Pessoa(usuarioId: 0),
    );

    setState(() {
      _erroCpf = null;
      _funcionarioEditandoId = funcionario.id;
      _pessoaOperacionalEditandoId = funcionario.pessoaId;

      _nomeController.text = pessoa.nome ?? '';
      _cpfController.text = pessoa.cpf ?? '';
      _telefoneController.text = pessoa.telefone ?? '';

      _cargoController.text = funcionario.cargo;
      _salarioController.text =
          funcionario.salario?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
      _dataContratacaoController.text = funcionario.dataContratacao ?? '';
      _dataDesligamentoController.text = funcionario.dataDesligamento ?? '';
      _observacaoController.text = funcionario.observacao ?? '';
      _status = funcionario.status;
    });
  }

  Future<void> _excluir(Funcionario funcionario) async {
    if (funcionario.id == null) return;

    await _funcionarioService.excluir(funcionario.id!);

    _mostrarMensagem('Funcionário removido.');
    _limparFormulario();
    await _carregarDados();
  }

  void _limparFormulario() {
    setState(() {
      _erroCpf = null;
      _funcionarioEditandoId = null;
      _pessoaOperacionalEditandoId = null;
      _status = 'Ativo';

      _nomeController.clear();
      _cpfController.clear();
      _telefoneController.clear();
      _cargoController.clear();
      _salarioController.clear();
      _dataContratacaoController.clear();
      _dataDesligamentoController.clear();
      _observacaoController.clear();
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _nomePessoa(int pessoaId) {
    final pessoa = _pessoasOperacionais.firstWhere(
      (p) => p.id == pessoaId,
      orElse: () => Pessoa(usuarioId: 0, nome: 'Pessoa não encontrada'),
    );

    return pessoa.nome ?? 'Sem nome';
  }

  String _formatarMoeda(double? valor) {
    if (valor == null) return 'R\$ 0,00';

    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    double width = 260,
    bool readOnly = false,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onTap: onTap,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propriedadeSelecionada = SessaoService.propriedadeSelecionada;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestão de Funcionários',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    propriedadeSelecionada == null
                        ? 'Nenhuma propriedade selecionada.'
                        : 'Propriedade atual: ${propriedadeSelecionada.nome}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _funcionarioEditandoId == null
                                  ? 'Novo funcionário'
                                  : 'Editar funcionário',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),

                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                _campo(
                                  controller: _nomeController,
                                  label: 'Nome',
                                  icon: Icons.person,
                                  width: 320,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe o nome.';
                                    }
                                    return null;
                                  },
                                ),
                                _campo(
                                  controller: _cpfController,
                                  label: 'CPF',
                                  icon: Icons.badge,
                                  width: 220,
                                  validator: (value) {
                                    if (_erroCpf != null) {
                                      return _erroCpf;
                                    }
                                    return null;
                                  },
                                ),
                                _campo(
                                  controller: _telefoneController,
                                  label: 'Telefone',
                                  icon: Icons.phone,
                                  width: 220,
                                ),
                                _campo(
                                  controller: _cargoController,
                                  label: 'Cargo/Função',
                                  icon: Icons.work,
                                  width: 260,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe o cargo.';
                                    }
                                    return null;
                                  },
                                ),
                                _campo(
                                  controller: _salarioController,
                                  label: 'Salário',
                                  icon: Icons.attach_money,
                                  width: 180,
                                  keyboardType: TextInputType.number,
                                ),
                                _campo(
                                  controller: _dataContratacaoController,
                                  label: 'Data contratação',
                                  icon: Icons.calendar_month,
                                  width: 220,
                                  readOnly: true,
                                  onTap: () => _selecionarData(
                                    _dataContratacaoController,
                                  ),
                                ),
                                SizedBox(
                                  width: 220,
                                  child: DropdownButtonFormField<String>(
                                    value: _status,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      prefixIcon: Icon(Icons.info),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Ativo',
                                        child: Text('Ativo'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Desligado',
                                        child: Text('Desligado'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _status = value ?? 'Ativo';
                                      });
                                    },
                                  ),
                                ),
                                if (_status == 'Desligado')
                                  _campo(
                                    controller: _dataDesligamentoController,
                                    label: 'Data desligamento',
                                    icon: Icons.event_busy,
                                    width: 220,
                                    readOnly: true,
                                    onTap: () => _selecionarData(
                                      _dataDesligamentoController,
                                    ),
                                    validator: (value) {
                                      if (_status == 'Desligado' &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
                                        return 'Informe a data.';
                                      }
                                      return null;
                                    },
                                  ),
                                _campo(
                                  controller: _observacaoController,
                                  label: 'Observação',
                                  icon: Icons.notes,
                                  width: 500,
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _salvar,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Salvar funcionário'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _limparFormulario,
                                  icon: const Icon(Icons.clear),
                                  label: const Text('Limpar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  Text(
                    'Funcionários cadastrados',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_carregando)
                    const Center(child: CircularProgressIndicator())
                  else if (_funcionarios.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Nenhum funcionário cadastrado.'),
                      ),
                    )
                  else
                    Column(
                      children: _funcionarios.map((funcionario) {
                        final desligado = funcionario.status == 'Desligado';

                        return Card(
                          elevation: 2,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: desligado
                                  ? Colors.red.shade100
                                  : AppTheme.accentColor,
                              child: Icon(
                                Icons.groups,
                                color: desligado
                                    ? Colors.red
                                    : AppTheme.primaryGreen,
                              ),
                            ),
                            title: Text(
                              _nomePessoa(funcionario.pessoaId),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${funcionario.cargo} • ${_formatarMoeda(funcionario.salario)} • ${funcionario.status}',
                            ),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  tooltip: 'Lançar folha',
                                  icon: const Icon(Icons.payments),
                                  color: AppTheme.primaryGreen,
                                  onPressed: () => _registrarFolha(funcionario),
                                ),
                                IconButton(
                                  tooltip: 'Editar',
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editar(funcionario),
                                ),
                                IconButton(
                                  tooltip: 'Excluir',
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () => _excluir(funcionario),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
