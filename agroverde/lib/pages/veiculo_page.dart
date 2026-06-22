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

  final List<String> _tipos = const [
    'Trator',
    'Caminhonete',
    'Caminhão',
    'Colheitadeira',
    'Pulverizador',
    'Outro',
  ];

  final List<String> _statusList = const ['Ativo', 'Manutenção', 'Vendido'];

  /// Lista fixa da página.
  ///
  /// Nesta versão simples, o tipo do combustível é salvo no campo
  /// "observacao" da tabela abastecimento para evitar nova migração no banco.
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

      _mostrarMensagem('Erro ao carregar veículos: $e');
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

    await _veiculoService.salvar(veiculo);

    if (!mounted) return;

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

    await _veiculoService.excluir(veiculo.id!);

    if (!mounted) return;

    _mostrarMensagem('Veículo excluído com sucesso.');
    await _carregarVeiculos();
  }

  Future<void> _abrirAbastecimentos(Veiculo veiculo) async {
    if (veiculo.id == null) return;

    final dataController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final litrosController = TextEditingController();
    final valorController = TextEditingController();

    String tipoCombustivelSelecionado = 'Diesel';

    List<Abastecimento> historico = await _abastecimentoService
        .listarPorVeiculoId(veiculo.id!);

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

                /// Nesta versão, o combustível escolhido é salvo em observação.
                observacao: tipoCombustivelSelecionado,
              );

              await _abastecimentoService.salvar(abastecimento);
              await _veiculoService.registrarAbastecimentoFinanceiro(
                propriedadeId: veiculo.propriedadeId,
                nomeVeiculo: veiculo.nome,
                valor: valor,
                data: dataController.text.trim(),
              );

              historico = await _abastecimentoService.listarPorVeiculoId(
                veiculo.id!,
              );

              litrosController.clear();
              valorController.clear();

              setDialogState(() {});
              await _carregarVeiculos();

              if (!mounted) return;
              _mostrarMensagem('Abastecimento registrado.');
            }

            Future<void> excluir(Abastecimento item) async {
              if (item.id == null) return;

              await _abastecimentoService.excluir(item.id!);

              historico = await _abastecimentoService.listarPorVeiculoId(
                veiculo.id!,
              );

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
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
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

  Future<void> _abrirManutencoes(Veiculo veiculo) async {
    if (veiculo.id == null) return;

    final dataController = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final tipoController = TextEditingController();
    final descricaoController = TextEditingController();
    final valorController = TextEditingController();
    final observacaoController = TextEditingController();

    List<ManutencaoVeiculo> historico = await _manutencaoService
        .listarPorVeiculoId(veiculo.id!);

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

              await _manutencaoService.salvar(manutencao);
              await _veiculoService.registrarManutencaoFinanceira(
                propriedadeId: veiculo.propriedadeId,
                nomeVeiculo: veiculo.nome,
                valor: valor,
                data: dataController.text.trim(),
              );

              historico = await _manutencaoService.listarPorVeiculoId(
                veiculo.id!,
              );

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

              await _manutencaoService.excluir(item.id!);

              historico = await _manutencaoService.listarPorVeiculoId(
                veiculo.id!,
              );

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
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veículos'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: propriedadeId == null
          ? const Center(
              child: Text(
                'Selecione uma propriedade para gerenciar os veículos.',
              ),
            )
          : _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cabecalho(),
                  const SizedBox(height: 20),
                  _resumoCards(),
                  const SizedBox(height: 20),
                  if (_mostrarFormulario) _formulario(),
                  if (_mostrarFormulario) const SizedBox(height: 20),
                  _listaVeiculos(),
                ],
              ),
            ),
    );
  }

  Widget _cabecalho() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veículos',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Gestão simples de veículos e máquinas da propriedade.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          onPressed: _novoVeiculo,
          icon: const Icon(Icons.add),
          label: const Text('Novo Veículo'),
        ),
      ],
    );
  }

  Widget _resumoCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _cardResumo('Veículos Ativos', _ativos.toString()),
        _cardResumo('Em Manutenção', _manutencao.toString()),
        _cardResumo('Vendidos', _vendidos.toString()),
        _cardResumo('Gasto Combustível', _moeda(_totalCombustivel)),
        _cardResumo('Gasto Manutenção', _moeda(_totalManutencao)),
      ],
    );
  }

  Widget _cardResumo(String titulo, String valor) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulario() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _veiculoEditando == null ? 'Novo Veículo' : 'Editar Veículo',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _campoTexto(
                    controller: _nomeController,
                    label: 'Nome',
                    obrigatorio: true,
                  ),
                  _dropdownTipo(),
                  _campoTexto(controller: _marcaController, label: 'Marca'),
                  _campoTexto(controller: _modeloController, label: 'Modelo'),
                  _campoTexto(
                    controller: _anoController,
                    label: 'Ano',
                    numero: true,
                  ),
                  _campoTexto(controller: _placaController, label: 'Placa'),
                  _campoTexto(
                    controller: _horimetroController,
                    label: 'Horímetro/Odômetro Atual',
                    numeroDecimal: true,
                  ),
                  _dropdownStatus(),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _salvarVeiculo,
                    child: Text(
                      _veiculoEditando == null ? 'Salvar' : 'Atualizar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _cancelarFormulario,
                    child: const Text('Cancelar'),
                  ),
                ],
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
    bool obrigatorio = false,
    bool numero = false,
    bool numeroDecimal = false,
  }) {
    return SizedBox(
      width: 260,
      child: TextFormField(
        controller: controller,
        keyboardType: numero || numeroDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
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

  Widget _dropdownTipo() {
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<String>(
        value: _tipoSelecionado,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          border: OutlineInputBorder(),
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

  Widget _dropdownStatus() {
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<String>(
        value: _statusSelecionado,
        decoration: const InputDecoration(
          labelText: 'Status',
          border: OutlineInputBorder(),
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
    if (_veiculos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nenhum veículo cadastrado.')),
        ),
      );
    }

    return Column(children: _veiculos.map(_cardVeiculo).toList());
  }

  Widget _cardVeiculo(Veiculo veiculo) {
    final id = veiculo.id;

    final double totalCombustivel = id == null
        ? 0.0
        : (_totalCombustivelPorVeiculo[id] ?? 0.0);

    final double totalManutencao = id == null
        ? 0.0
        : (_totalManutencaoPorVeiculo[id] ?? 0.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    veiculo.nome,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 18,
                    runSpacing: 8,
                    children: [
                      _info('Tipo', veiculo.tipo),
                      _info(
                        'Marca',
                        veiculo.marca.isEmpty ? '-' : veiculo.marca,
                      ),
                      _info(
                        'Modelo',
                        veiculo.modelo.isEmpty ? '-' : veiculo.modelo,
                      ),
                      _info(
                        'Ano',
                        veiculo.ano == 0 ? '-' : veiculo.ano.toString(),
                      ),
                      _info(
                        'Placa',
                        veiculo.placa.isEmpty ? '-' : veiculo.placa,
                      ),
                      _statusChip(veiculo.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _miniResumo('Combustível', _moeda(totalCombustivel)),
                      _miniResumo('Manutenção', _moeda(totalManutencao)),
                      _miniResumo(
                        'Horímetro/Odômetro',
                        veiculo.horimetroOdometroAtual == 0
                            ? '-'
                            : veiculo.horimetroOdometroAtual.toString(),
                      ),
                    ],
                  ),
                  if (veiculo.observacao.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Obs.: ${veiculo.observacao}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _botaoCard(
                  texto: 'Abastecimento',
                  onPressed: () => _abrirAbastecimentos(veiculo),
                ),
                const SizedBox(width: 8),
                _botaoCard(
                  texto: 'Manutenção',
                  onPressed: () => _abrirManutencoes(veiculo),
                ),
                const SizedBox(width: 8),
                _botaoCard(texto: 'Editar', onPressed: () => _editar(veiculo)),
                const SizedBox(width: 8),
                _botaoCard(
                  texto: 'Excluir',
                  vermelho: true,
                  onPressed: () => _excluir(veiculo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoCard({
    required String texto,
    required VoidCallback onPressed,
    bool vermelho = false,
  }) {
    final corBotao = vermelho ? Colors.red : AppTheme.primaryGreen;

    return SizedBox(
      width: 125,
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: corBotao,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _info(String label, String valor) {
    return Text('$label: $valor');
  }

  Widget _miniResumo(String titulo, String valor) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
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
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => excluir(item),
            ),
          ),
        );
      }).toList(),
    );
  }
}
