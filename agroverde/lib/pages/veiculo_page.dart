import 'package:flutter/material.dart';

import '../domain/entities/abastecimento.dart';
import '../domain/entities/manutencao_veiculo.dart';
import '../domain/entities/veiculo.dart';
import '../domain/services/abastecimento_service.dart';
import '../domain/services/manutencao_veiculo_service.dart';
import '../domain/services/sessao_service.dart';
import '../domain/services/veiculo_service.dart';
import '../theme/app_theme.dart';

class VeiculoPage extends StatefulWidget {
  const VeiculoPage({super.key});

  @override
  State<VeiculoPage> createState() => _VeiculoPageState();
}

class _VeiculoPageState extends State<VeiculoPage> {
  final VeiculoService _veiculoService = VeiculoService();
  final AbastecimentoService _abastecimentoService = AbastecimentoService();
  final ManutencaoVeiculoService _manutencaoService =
      ManutencaoVeiculoService();

  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anoController = TextEditingController();
  final _placaController = TextEditingController();
  final _horimetroController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Veiculo> _veiculos = [];

  final Map<int, double> _totalCombustivelPorVeiculo = {};
  final Map<int, double> _totalManutencaoPorVeiculo = {};

  Veiculo? _veiculoEditando;

  String _tipoSelecionado = 'Trator';
  String _statusSelecionado = 'Ativo';

  bool _mostrarFormulario = false;
  bool _carregando = false;

  // Evita cadastros duplicados com cliques repetidos.
  bool _salvandoVeiculo = false;

  final List<String> _tipos = const [
    'Trator',
    'Caminhonete',
    'Caminhão',
    'Colheitadeira',
    'Pulverizador',
    'Outro',
  ];

  final List<String> _statusList = const ['Ativo', 'Manutenção', 'Vendido'];

  final List<String> _tiposCombustivel = const [
    'Diesel',
    'Gasolina',
    'Etanol',
    'Querosene',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _carregarVeiculos();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anoController.dispose();
    _placaController.dispose();
    _horimetroController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  /// Carrega os veículos e os indicadores financeiros.
  Future<void> _carregarVeiculos() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) return;

    setState(() {
      _carregando = true;
    });

    try {
      final lista = await _veiculoService.listarPorPropriedade(propriedadeId);

      final Map<int, double> combustivel = {};
      final Map<int, double> manutencao = {};

      for (final veiculo in lista) {
        final id = veiculo.id;

        if (id == null) continue;

        combustivel[id] = await _abastecimentoService.totalGastoVeiculo(id);
        manutencao[id] = await _manutencaoService.totalGastoVeiculo(id);
      }

      if (!mounted) return;

      setState(() {
        _veiculos = lista;
        _totalCombustivelPorVeiculo
          ..clear()
          ..addAll(combustivel);
        _totalManutencaoPorVeiculo
          ..clear()
          ..addAll(manutencao);
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
      });

      _mostrarMensagem(
        'Erro ao carregar veículos: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  Future<void> _salvarVeiculo() async {
    if (!_formKey.currentState!.validate()) return;

    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      _mostrarMensagem(
        'Selecione uma propriedade antes de cadastrar veículos.',
      );
      return;
    }

    final veiculo = Veiculo(
      id: _veiculoEditando?.id,
      propriedadeId: propriedadeId,
      nome: _nomeController.text.trim(),
      tipo: _tipoSelecionado,
      marca: _marcaController.text.trim(),
      modelo: _modeloController.text.trim(),
      ano: int.tryParse(_anoController.text.trim()) ?? 0,
      placa: _placaController.text.trim(),
      horimetroOdometroAtual: _parseDouble(_horimetroController.text),
      status: _statusSelecionado,
      valorVenda: _veiculoEditando?.valorVenda ?? 0,
      dataVenda: _veiculoEditando?.dataVenda,
      observacao: _observacaoController.text.trim(),
    );

    if (_salvandoVeiculo) return;

    setState(() => _salvandoVeiculo = true);

    try {
      await _veiculoService.salvar(veiculo);
    } catch (e) {
      if (mounted) setState(() => _salvandoVeiculo = false);
      _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
      return;
    }

    if (!mounted) return;

    setState(() => _salvandoVeiculo = false);

    _mostrarMensagem(
      _veiculoEditando == null
          ? 'Veículo cadastrado com sucesso.'
          : 'Veículo atualizado com sucesso.',
    );

    _limparFormulario();
    await _carregarVeiculos();
  }

  void _editar(Veiculo veiculo) {
    setState(() {
      _veiculoEditando = veiculo;

      _nomeController.text = veiculo.nome;
      _marcaController.text = veiculo.marca;
      _modeloController.text = veiculo.modelo;
      _anoController.text = veiculo.ano == 0 ? '' : veiculo.ano.toString();
      _placaController.text = veiculo.placa;
      _horimetroController.text = veiculo.horimetroOdometroAtual == 0
          ? ''
          : veiculo.horimetroOdometroAtual.toString();
      _observacaoController.text = veiculo.observacao;

      _tipoSelecionado = _tipos.contains(veiculo.tipo)
          ? veiculo.tipo
          : 'Trator';

      _statusSelecionado = _statusList.contains(veiculo.status)
          ? veiculo.status
          : 'Ativo';

      _mostrarFormulario = true;
    });
  }

  Future<void> _excluir(Veiculo veiculo) async {
    if (veiculo.id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir veículo'),
          content: Text('Deseja realmente excluir "${veiculo.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await _veiculoService.excluir(veiculo.id!);
    } catch (e) {
      _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
      return;
    }

    if (!mounted) return;

    _mostrarMensagem('Veículo excluído com sucesso.');
    await _carregarVeiculos();
  }

  /// Gerencia os abastecimentos do veículo.
  Future<void> _abrirAbastecimentos(Veiculo veiculo) async {
    if (veiculo.id == null) return;

    final dataController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final litrosController = TextEditingController();
    final valorController = TextEditingController();

    String tipoCombustivelSelecionado = 'Diesel';

    // Evita dois abastecimentos (e duas despesas) com cliques repetidos.
    var salvando = false;

    List<Abastecimento> historico;

    try {
      historico = await _abastecimentoService.listarPorVeiculoId(veiculo.id!);
    } catch (e) {
      _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> salvar() async {
              final litros = _parseDouble(litrosController.text);
              final valor = _parseDouble(valorController.text);

              if (litros <= 0 || valor <= 0) {
                _mostrarMensagem('Informe litros e valor total.');
                return;
              }

              final abastecimento = Abastecimento(
                veiculoId: veiculo.id!,
                data: dataController.text.trim(),
                litros: litros,
                valorTotal: valor,
                observacao: tipoCombustivelSelecionado,
              );

              if (salvando) return;
              salvando = true;

              // A API grava o abastecimento e a despesa no Financeiro
              // na mesma transação.
              try {
                await _abastecimentoService.salvar(abastecimento);
                historico = await _abastecimentoService.listarPorVeiculoId(
                  veiculo.id!,
                );
              } catch (e) {
                _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
                return;
              } finally {
                salvando = false;
              }

              litrosController.clear();
              valorController.clear();

              setDialogState(() {});
              await _carregarVeiculos();

              if (!mounted) return;
              _mostrarMensagem('Abastecimento registrado.');
            }

            Future<void> excluir(Abastecimento item) async {
              if (item.id == null) return;

              try {
                await _abastecimentoService.excluir(item.id!);
                historico = await _abastecimentoService.listarPorVeiculoId(
                  veiculo.id!,
                );
              } catch (e) {
                _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
                return;
              }

              setDialogState(() {});
              await _carregarVeiculos();

              if (!mounted) return;
              _mostrarMensagem('Abastecimento excluído.');
            }

            return AlertDialog(
              title: Text('Abastecimentos - ${veiculo.nome}'),
              content: SizedBox(
                width: 680,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _campoDialog(
                            controller: dataController,
                            label: 'Data',
                            width: 150,
                          ),
                          SizedBox(
                            width: 170,
                            child: DropdownButtonFormField<String>(
                              value: tipoCombustivelSelecionado,
                              decoration: const InputDecoration(
                                labelText: 'Combustível',
                                border: OutlineInputBorder(),
                              ),
                              items: _tiposCombustivel.map((tipo) {
                                return DropdownMenuItem(
                                  value: tipo,
                                  child: Text(tipo),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;

                                setDialogState(() {
                                  tipoCombustivelSelecionado = value;
                                });
                              },
                            ),
                          ),
                          _campoDialog(
                            controller: litrosController,
                            label: 'Litros',
                            width: 150,
                            numeroDecimal: true,
                          ),
                          _campoDialog(
                            controller: valorController,
                            label: 'Valor Total',
                            width: 160,
                            numeroDecimal: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: salvar,
                          child: const Text('Salvar Abastecimento'),
                        ),
                      ),
                      const Divider(height: 28),
                      _historicoAbastecimento(historico, excluir),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );

    dataController.dispose();
    litrosController.dispose();
    valorController.dispose();
  }

  /// Exibe os dados e ações disponíveis para o veículo.
  Future<void> _abrirManutencoes(Veiculo veiculo) async {
    if (veiculo.id == null) return;

    final dataController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final tipoController = TextEditingController();
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();
    final observacaoController = TextEditingController();

    // Evita duas manutenções (e duas despesas) com cliques repetidos.
    var salvando = false;

    List<ManutencaoVeiculo> historico;

    try {
      historico = await _manutencaoService.listarPorVeiculoId(veiculo.id!);
    } catch (e) {
      _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> salvar() async {
              final valor = _parseDouble(valorController.text);

              if (tipoController.text.trim().isEmpty || valor <= 0) {
                _mostrarMensagem('Informe o tipo e o valor da manutenção.');
                return;
              }

              final manutencao = ManutencaoVeiculo(
                veiculoId: veiculo.id!,
                data: dataController.text.trim(),
                tipo: tipoController.text.trim(),
                descricao: descricaoController.text.trim(),
                valor: valor,
                observacao: observacaoController.text.trim(),
              );

              if (salvando) return;
              salvando = true;

              // A API grava a manutenção e a despesa no Financeiro
              // na mesma transação.
              try {
                await _manutencaoService.salvar(manutencao);
                historico = await _manutencaoService.listarPorVeiculoId(
                  veiculo.id!,
                );
              } catch (e) {
                _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
                return;
              } finally {
                salvando = false;
              }

              tipoController.clear();
              descricaoController.clear();
              valorController.clear();
              observacaoController.clear();

              setDialogState(() {});
              await _carregarVeiculos();

              if (!mounted) return;
              _mostrarMensagem('Manutenção registrada.');
            }

            Future<void> excluir(ManutencaoVeiculo item) async {
              if (item.id == null) return;

              try {
                await _manutencaoService.excluir(item.id!);
                historico = await _manutencaoService.listarPorVeiculoId(
                  veiculo.id!,
                );
              } catch (e) {
                _mostrarMensagem(e.toString().replaceAll('Exception: ', ''));
                return;
              }

              setDialogState(() {});
              await _carregarVeiculos();

              if (!mounted) return;
              _mostrarMensagem('Manutenção excluída.');
            }

            return AlertDialog(
              title: Text('Manutenções - ${veiculo.nome}'),
              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _campoDialog(
                            controller: dataController,
                            label: 'Data',
                            width: 160,
                          ),
                          _campoDialog(
                            controller: tipoController,
                            label: 'Tipo',
                            width: 210,
                          ),
                          _campoDialog(
                            controller: valorController,
                            label: 'Valor',
                            width: 170,
                            numeroDecimal: true,
                          ),
                          _campoDialog(
                            controller: descricaoController,
                            label: 'Descrição',
                            width: 662,
                          ),
                          _campoDialog(
                            controller: observacaoController,
                            label: 'Observação',
                            width: 662,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: salvar,
                          child: const Text('Salvar Manutenção'),
                        ),
                      ),
                      const Divider(height: 28),
                      _historicoManutencao(historico, excluir),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );

    dataController.dispose();
    tipoController.dispose();
    descricaoController.dispose();
    valorController.dispose();
    observacaoController.dispose();
  }

  void _novoVeiculo() {
    setState(() {
      _limparCampos();
      _mostrarFormulario = true;
    });
  }

  void _cancelarFormulario() {
    setState(() {
      _limparCampos();
      _mostrarFormulario = false;
    });
  }

  void _limparFormulario() {
    setState(() {
      _limparCampos();
      _mostrarFormulario = false;
    });
  }

  void _limparCampos() {
    _veiculoEditando = null;

    _nomeController.clear();
    _marcaController.clear();
    _modeloController.clear();
    _anoController.clear();
    _placaController.clear();
    _horimetroController.clear();
    _observacaoController.clear();

    _tipoSelecionado = 'Trator';
    _statusSelecionado = 'Ativo';
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String _moeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  int get _ativos => _veiculos.where((v) => v.status == 'Ativo').length;

  int get _manutencao =>
      _veiculos.where((v) => v.status == 'Manutenção').length;

  int get _vendidos => _veiculos.where((v) => v.status == 'Vendido').length;

  double get _totalCombustivel {
    return _totalCombustivelPorVeiculo.values.fold(0.0, (soma, valor) {
      return soma + valor;
    });
  }

  double get _totalManutencao {
    return _totalManutencaoPorVeiculo.values.fold(0.0, (soma, valor) {
      return soma + valor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final propriedadeId = SessaoService.propriedadeId;
    final propriedadeNome = SessaoService.propriedadeNome;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veículos'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      propriedadeNome == null
                          ? 'Nenhuma propriedade em foco.'
                          : 'Propriedade em foco: $propriedadeNome',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (propriedadeId == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Selecione uma propriedade para gerenciar os veículos.',
                      ),
                    ),
                  )
                else if (_carregando)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _resumoCards(),
                  const SizedBox(height: 24),
                  if (!_mostrarFormulario) _cabecalho(),
                  if (_mostrarFormulario) _formulario(),
                  const SizedBox(height: 24),
                  _listaVeiculos(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 45)),
        onPressed: _novoVeiculo,
        icon: const Icon(Icons.add),
        label: const Text('Novo Veículo'),
      ),
    );
  }

  Widget _resumoCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _cardResumo('Veículos ativos', _ativos.toString(), Icons.local_shipping),
        _cardResumo(
          'Em manutenção',
          _manutencao.toString(),
          Icons.build,
          cor: _manutencao > 0 ? Colors.orange.shade800 : null,
        ),
        _cardResumo('Vendidos', _vendidos.toString(), Icons.sell),
        _cardResumo(
          'Gasto com combustível',
          _moeda(_totalCombustivel),
          Icons.local_gas_station,
        ),
        _cardResumo(
          'Gasto com manutenção',
          _moeda(_totalManutencao),
          Icons.handyman,
        ),
      ],
    );
  }

  // Mesmo padrão das boxes do Dashboard: ícone, valor e título.
  Widget _cardResumo(String titulo, String valor, IconData icone, {Color? cor}) {
    return SizedBox(
      width: 184,
      height: 130,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(icone, color: cor ?? AppTheme.primaryGreen, size: 30),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(titulo, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _veiculoEditando == null
                    ? 'Cadastro de Veículo'
                    : 'Editar Veículo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Duas colunas em telas largas, uma em telas estreitas.
                  final largura = constraints.maxWidth >= 640
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _campoTexto(
                        controller: _nomeController,
                        label: 'Nome',
                        icone: Icons.local_shipping,
                        largura: largura,
                        obrigatorio: true,
                      ),
                      _dropdownTipo(largura),
                      _campoTexto(
                        controller: _marcaController,
                        label: 'Marca',
                        icone: Icons.factory,
                        largura: largura,
                      ),
                      _campoTexto(
                        controller: _modeloController,
                        label: 'Modelo',
                        icone: Icons.directions_car,
                        largura: largura,
                      ),
                      _campoTexto(
                        controller: _anoController,
                        label: 'Ano',
                        icone: Icons.calendar_today,
                        largura: largura,
                        numero: true,
                      ),
                      _campoTexto(
                        controller: _placaController,
                        label: 'Placa',
                        icone: Icons.pin,
                        largura: largura,
                      ),
                      _campoTexto(
                        controller: _horimetroController,
                        label: 'Horímetro/Odômetro atual',
                        icone: Icons.speed,
                        largura: largura,
                        numeroDecimal: true,
                      ),
                      _dropdownStatus(largura),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                onPressed: _salvandoVeiculo ? null : _salvarVeiculo,
                icon: Icon(_veiculoEditando == null ? Icons.save : Icons.edit),
                label: Text(
                  _veiculoEditando == null
                      ? 'Salvar Veículo'
                      : 'Salvar Alterações',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                ),
                onPressed: _cancelarFormulario,
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    required double largura,
    bool obrigatorio = false,
    bool numero = false,
    bool numeroDecimal = false,
  }) {
    return SizedBox(
      width: largura,
      child: TextFormField(
        controller: controller,
        keyboardType: numero || numeroDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icone),
        ),
        validator: obrigatorio
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe $label';
                }

                return null;
              }
            : null,
      ),
    );
  }

  Widget _campoDialog({
    required TextEditingController controller,
    required String label,
    required double width,
    bool numeroDecimal = false,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: numeroDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _dropdownTipo(double largura) {
    return SizedBox(
      width: largura,
      child: DropdownButtonFormField<String>(
        value: _tipoSelecionado,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          prefixIcon: Icon(Icons.category),
        ),
        items: _tipos.map((tipo) {
          return DropdownMenuItem(value: tipo, child: Text(tipo));
        }).toList(),
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _tipoSelecionado = value;
          });
        },
      ),
    );
  }

  Widget _dropdownStatus(double largura) {
    return SizedBox(
      width: largura,
      child: DropdownButtonFormField<String>(
        value: _statusSelecionado,
        decoration: const InputDecoration(
          labelText: 'Status',
          prefixIcon: Icon(Icons.flag),
        ),
        items: _statusList.map((status) {
          return DropdownMenuItem(value: status, child: Text(status));
        }).toList(),
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _statusSelecionado = value;
          });
        },
      ),
    );
  }

  Widget _listaVeiculos() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Veículos cadastrados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Exibindo ${_veiculos.length} veículo(s)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            if (_veiculos.isEmpty)
              const Text('Nenhum veículo cadastrado.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _veiculos.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) =>
                    _cardVeiculo(_veiculos[index]),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconeTipo(String tipo) {
    switch (tipo) {
      case 'Trator':
        return Icons.agriculture;
      case 'Colheitadeira':
        return Icons.grass;
      case 'Pulverizador':
        return Icons.water_drop;
      case 'Caminhão':
        return Icons.local_shipping;
      case 'Caminhonete':
        return Icons.directions_car;
      default:
        return Icons.build_circle;
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Ativo':
        return Colors.green;
      case 'Manutenção':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _cardVeiculo(Veiculo veiculo) {
    final id = veiculo.id;

    final double totalCombustivel = id == null
        ? 0.0
        : (_totalCombustivelPorVeiculo[id] ?? 0.0);

    final double totalManutencao = id == null
        ? 0.0
        : (_totalManutencaoPorVeiculo[id] ?? 0.0);

    final detalhes = [
      veiculo.tipo,
      if (veiculo.marca.isNotEmpty) veiculo.marca,
      if (veiculo.modelo.isNotEmpty) veiculo.modelo,
      if (veiculo.ano != 0) veiculo.ano.toString(),
      if (veiculo.placa.isNotEmpty) 'Placa ${veiculo.placa}',
    ].join(' | ');

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                veiculo.nome,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _statusChip(veiculo.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(detalhes, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 4),
        Text(
          'Combustível: ${_moeda(totalCombustivel)} | '
          'Manutenção: ${_moeda(totalManutencao)} | '
          'Horímetro/Odômetro: ${veiculo.horimetroOdometroAtual == 0 ? '-' : veiculo.horimetroOdometroAtual.toString()}',
        ),
        if (veiculo.observacao.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Obs.: ${veiculo.observacao}',
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ],
    );

    final botoes = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
          onPressed: () => _abrirAbastecimentos(veiculo),
          icon: const Icon(Icons.local_gas_station, size: 18),
          label: const Text('Abastecimento'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
          onPressed: () => _abrirManutencoes(veiculo),
          icon: const Icon(Icons.handyman, size: 18),
          label: const Text('Manutenção'),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
          onPressed: () => _editar(veiculo),
          child: const Text('Editar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 38),
          ),
          onPressed: () => _excluir(veiculo),
          child: const Text('Excluir'),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final icone = Padding(
            padding: const EdgeInsets.only(top: 2, right: 16),
            child: Icon(
              _iconeTipo(veiculo.tipo),
              color: _corStatus(veiculo.status),
              size: 28,
            ),
          );

          // Em telas largas os botões ficam à direita; em estreitas, abaixo.
          if (constraints.maxWidth >= 820) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icone,
                Expanded(child: info),
                const SizedBox(width: 16),
                botoes,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icone,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 12), botoes],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    Color corFundo;
    Color corTexto;

    switch (status) {
      case 'Ativo':
        corFundo = AppTheme.accentColor;
        corTexto = AppTheme.primaryGreen;
        break;
      case 'Manutenção':
        corFundo = const Color(0xFFFFF3CD);
        corTexto = const Color(0xFF8A5A00);
        break;
      case 'Vendido':
        corFundo = const Color(0xFFE9ECEF);
        corTexto = Colors.black54;
        break;
      default:
        corFundo = const Color(0xFFE9ECEF);
        corTexto = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: corTexto, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _historicoAbastecimento(
    List<Abastecimento> historico,
    Future<void> Function(Abastecimento item) excluir,
  ) {
    if (historico.isEmpty) {
      return const Text('Nenhum abastecimento registrado.');
    }

    return Column(
      children: historico.map((item) {
        final combustivel = item.observacao.isEmpty
            ? 'Não informado'
            : item.observacao;

        return Card(
          elevation: 0,
          color: AppTheme.backgroundColor,
          child: ListTile(
            dense: true,
            title: Text(
              '${item.data} • $combustivel • ${_moeda(item.valorTotal)}',
            ),
            subtitle: Text(
              'Litros: ${item.litros.toStringAsFixed(2).replaceAll('.', ',')}',
            ),
            trailing: IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => excluir(item),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _historicoManutencao(
    List<ManutencaoVeiculo> historico,
    Future<void> Function(ManutencaoVeiculo item) excluir,
  ) {
    if (historico.isEmpty) {
      return const Text('Nenhuma manutenção registrada.');
    }

    return Column(
      children: historico.map((item) {
        return Card(
          elevation: 0,
          color: AppTheme.backgroundColor,
          child: ListTile(
            dense: true,
            title: Text('${item.data} • ${item.tipo} • ${_moeda(item.valor)}'),
            subtitle: Text(
              '${item.descricao}'
              '${item.observacao.isEmpty ? '' : ' | ${item.observacao}'}',
            ),
            trailing: IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => excluir(item),
            ),
          ),
        );
      }).toList(),
    );
  }
}