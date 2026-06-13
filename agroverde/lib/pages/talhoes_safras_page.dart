import 'package:flutter/material.dart';

import '../domain/entities/talhao.dart';
import '../domain/entities/safra.dart';
import '../domain/services/sessao_service.dart';
import '../domain/services/talhao_service.dart';
import '../domain/services/safra_service.dart';

class TalhoesSafrasPage extends StatefulWidget {
  const TalhoesSafrasPage({super.key});

  @override
  State<TalhoesSafrasPage> createState() => _TalhoesSafrasPageState();
}

class _TalhoesSafrasPageState extends State<TalhoesSafrasPage> {
  final _formKey = GlobalKey<FormState>();

  final TalhaoService _talhaoService = TalhaoService();
  final SafraService _safraService = SafraService();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _tipoSoloController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  final TextEditingController _nomeSafraController = TextEditingController();
  final TextEditingController _culturaController = TextEditingController();
  final TextEditingController _variedadeController = TextEditingController();
  final TextEditingController _dataPlantioController = TextEditingController();
  final TextEditingController _dataColheitaPrevistaController =
      TextEditingController();
  final TextEditingController _producaoEstimadaController =
      TextEditingController();
  final TextEditingController _observacaoSafraController =
      TextEditingController();

  List<Talhao> _talhoes = [];
  List<Safra> _safras = [];

  /// Talhão atualmente selecionado.
  ///
  /// Todas as safras listadas/cadastradas
  /// serão vinculadas a este talhão.
  Talhao? _talhaoSelecionado;

  bool _mostrarFormulario = false;
  bool _editando = false;
  int? _talhaoEditandoId;

  bool _mostrarFormularioSafra = false;
  bool _editandoSafra = false;
  int? _safraEditandoId;

  String _statusSafra = 'Planejada';

  @override
  void initState() {
    super.initState();
    _carregarTalhoes();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _areaController.dispose();
    _tipoSoloController.dispose();
    _observacaoController.dispose();

    _nomeSafraController.dispose();
    _culturaController.dispose();
    _variedadeController.dispose();
    _dataPlantioController.dispose();
    _dataColheitaPrevistaController.dispose();
    _producaoEstimadaController.dispose();
    _observacaoSafraController.dispose();

    super.dispose();
  }

  Future<void> _carregarTalhoes() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      return;
    }

    final lista = await _talhaoService.listarPorPropriedadeId(propriedadeId);

    setState(() {
      _talhoes = lista;
    });
  }

  Future<void> _carregarSafras(int talhaoId) async {
    final lista = await _safraService.listarPorTalhaoId(talhaoId);

    setState(() {
      _safras = lista;
    });
  }

  Future<void> _selecionarData(TextEditingController controller) async {
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (dataSelecionada == null) {
      return;
    }

    final dia = dataSelecionada.day.toString().padLeft(2, '0');
    final mes = dataSelecionada.month.toString().padLeft(2, '0');
    final ano = dataSelecionada.year.toString();

    controller.text = '$dia/$mes/$ano';
  }

  Future<void> _salvarTalhao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma propriedade em foco primeiro.'),
        ),
      );
      return;
    }

    final talhao = Talhao(
      id: _talhaoEditandoId,
      propriedadeId: propriedadeId,
      nome: _nomeController.text.trim(),
      area: double.parse(_areaController.text.replaceAll(',', '.')),
      tipoSolo: _tipoSoloController.text.trim(),
      observacao: _observacaoController.text.trim(),
      ativo: true,
    );

    try {
      await _talhaoService.salvar(talhao);

      await _carregarTalhoes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando
                ? 'Talhão atualizado com sucesso!'
                : 'Talhão cadastrado com sucesso!',
          ),
        ),
      );

      _cancelarFormulario();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _salvarSafra() async {
    if (_talhaoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um talhão primeiro.')),
      );
      return;
    }

    final safra = Safra(
      id: _safraEditandoId,
      talhaoId: _talhaoSelecionado!.id!,
      nome: _nomeSafraController.text.trim(),
      cultura: _culturaController.text.trim(),
      variedade: _variedadeController.text.trim(),
      dataPlantio: _dataPlantioController.text.trim(),
      dataColheitaPrevista: _dataColheitaPrevistaController.text.trim(),
      producaoEstimada: _producaoEstimadaController.text.trim().isEmpty
          ? null
          : double.parse(_producaoEstimadaController.text.replaceAll(',', '.')),
      status: _statusSafra,
      observacao: _observacaoSafraController.text.trim(),
    );

    try {
      await _safraService.salvar(safra);

      await _carregarSafras(_talhaoSelecionado!.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editandoSafra
                ? 'Safra atualizada com sucesso!'
                : 'Safra cadastrada com sucesso!',
          ),
        ),
      );

      _cancelarFormularioSafra();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _excluirTalhao(Talhao talhao) async {
    await _talhaoService.excluir(talhao.id!);

    if (_talhaoSelecionado?.id == talhao.id) {
      setState(() {
        _talhaoSelecionado = null;
        _safras = [];
      });
    }

    await _carregarTalhoes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Talhão excluído com sucesso!')),
    );
  }

  Future<void> _excluirSafra(Safra safra) async {
    await _safraService.excluir(safra.id!);

    await _carregarSafras(_talhaoSelecionado!.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Safra excluída com sucesso!')),
    );
  }

  void _abrirFormularioCadastro() {
    _limparCampos();

    setState(() {
      _mostrarFormulario = true;
      _editando = false;
      _talhaoEditandoId = null;
    });
  }

  void _abrirFormularioSafra() {
    _limparCamposSafra();

    setState(() {
      _mostrarFormularioSafra = true;
      _editandoSafra = false;
      _safraEditandoId = null;
      _statusSafra = 'Planejada';
    });
  }

  void _editarTalhao(Talhao talhao) {
    _nomeController.text = talhao.nome;
    _areaController.text = talhao.area.toString();
    _tipoSoloController.text = talhao.tipoSolo ?? '';
    _observacaoController.text = talhao.observacao ?? '';

    setState(() {
      _mostrarFormulario = true;
      _editando = true;
      _talhaoEditandoId = talhao.id;
    });
  }

  void _editarSafra(Safra safra) {
    _nomeSafraController.text = safra.nome;
    _culturaController.text = safra.cultura;
    _variedadeController.text = safra.variedade ?? '';
    _dataPlantioController.text = safra.dataPlantio;
    _dataColheitaPrevistaController.text = safra.dataColheitaPrevista ?? '';
    _producaoEstimadaController.text = safra.producaoEstimada?.toString() ?? '';
    _observacaoSafraController.text = safra.observacao ?? '';

    setState(() {
      _mostrarFormularioSafra = true;
      _editandoSafra = true;
      _safraEditandoId = safra.id;
      _statusSafra = safra.status;
    });
  }

  void _selecionarTalhao(Talhao talhao) async {
    setState(() {
      _talhaoSelecionado = talhao;
      _mostrarFormularioSafra = false;
    });

    await _carregarSafras(talhao.id!);
  }

  void _cancelarFormulario() {
    _limparCampos();

    setState(() {
      _mostrarFormulario = false;
      _editando = false;
      _talhaoEditandoId = null;
    });
  }

  void _cancelarFormularioSafra() {
    _limparCamposSafra();

    setState(() {
      _mostrarFormularioSafra = false;
      _editandoSafra = false;
      _safraEditandoId = null;
      _statusSafra = 'Planejada';
    });
  }

  void _limparCampos() {
    _nomeController.clear();
    _areaController.clear();
    _tipoSoloController.clear();
    _observacaoController.clear();
  }

  void _limparCamposSafra() {
    _nomeSafraController.clear();
    _culturaController.clear();
    _variedadeController.clear();
    _dataPlantioController.clear();
    _dataColheitaPrevistaController.clear();
    _producaoEstimadaController.clear();
    _observacaoSafraController.clear();
  }

  bool _talhaoEstaSelecionado(Talhao talhao) {
    return _talhaoSelecionado?.id == talhao.id;
  }

  @override
  Widget build(BuildContext context) {
    final propriedadeNome = SessaoService.propriedadeNome;

    return Scaffold(
      appBar: AppBar(title: const Text('Talhões e Safras')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 900,
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

                if (!_mostrarFormulario)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _abrirFormularioCadastro,
                      icon: const Icon(Icons.add),
                      label: const Text('Novo Talhão'),
                    ),
                  ),

                if (_mostrarFormulario) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(
                              _editando
                                  ? 'Editar Talhão'
                                  : 'Cadastro de Talhão',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome do talhão',
                                prefixIcon: Icon(Icons.agriculture),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome do talhão';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _areaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Área do talhão (hectares)',
                                prefixIcon: Icon(Icons.square_foot),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe a área do talhão';
                                }

                                final area = double.tryParse(
                                  value.replaceAll(',', '.'),
                                );

                                if (area == null || area <= 0) {
                                  return 'Informe uma área válida';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _tipoSoloController,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de solo',
                                prefixIcon: Icon(Icons.terrain),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _observacaoController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Observação',
                                prefixIcon: Icon(Icons.description),
                              ),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _salvarTalhao,
                                child: Text(
                                  _editando
                                      ? 'Salvar Alterações'
                                      : 'Salvar Talhão',
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _cancelarFormulario,
                                child: const Text('Cancelar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Talhões cadastrados',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (SessaoService.propriedadeId == null)
                          const Text(
                            'Selecione uma propriedade em foco para gerenciar os talhões.',
                          )
                        else if (_talhoes.isEmpty)
                          const Text('Nenhum talhão cadastrado.')
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _talhoes.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final talhao = _talhoes[index];
                              final selecionado = _talhaoEstaSelecionado(
                                talhao,
                              );

                              return ListTile(
                                leading: Icon(
                                  selecionado
                                      ? Icons.check_circle
                                      : Icons.agriculture,
                                  color: selecionado
                                      ? Colors.green
                                      : const Color(0xFF064E2F),
                                ),
                                title: Text(talhao.nome),
                                subtitle: Text(
                                  'Área: ${talhao.area} ha'
                                  '${talhao.tipoSolo == null || talhao.tipoSolo!.isEmpty ? '' : ' | Solo: ${talhao.tipoSolo}'}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _selecionarTalhao(talhao);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: selecionado
                                            ? const Color(0xFF064E2F)
                                            : null,
                                        foregroundColor: selecionado
                                            ? Colors.white
                                            : null,
                                      ),
                                      child: Text(
                                        selecionado
                                            ? 'Selecionado'
                                            : 'Selecionar',
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        _editarTalhao(talhao);
                                      },
                                      child: const Text('Editar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _excluirTalhao(talhao);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Excluir'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safras',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (_talhaoSelecionado == null)
                          const Text(
                            'Selecione um talhão para visualizar as safras.',
                          )
                        else ...[
                          Text(
                            'Talhão selecionado: ${_talhaoSelecionado!.nome}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 16),

                          if (!_mostrarFormularioSafra)
                            ElevatedButton.icon(
                              onPressed: _abrirFormularioSafra,
                              icon: const Icon(Icons.add),
                              label: const Text('Nova Safra'),
                            ),

                          if (_mostrarFormularioSafra) ...[
                            const SizedBox(height: 16),

                            Text(
                              _editandoSafra
                                  ? 'Editar Safra'
                                  : 'Cadastro de Safra',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _nomeSafraController,
                              decoration: const InputDecoration(
                                labelText: 'Nome da safra',
                                prefixIcon: Icon(Icons.grass),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _culturaController,
                              decoration: const InputDecoration(
                                labelText: 'Cultura',
                                prefixIcon: Icon(Icons.eco),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _variedadeController,
                              decoration: const InputDecoration(
                                labelText: 'Variedade',
                                prefixIcon: Icon(Icons.spa),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _dataPlantioController,
                              readOnly: true,
                              onTap: () {
                                _selecionarData(_dataPlantioController);
                              },
                              decoration: const InputDecoration(
                                labelText: 'Data de plantio',
                                hintText: 'Selecione a data',
                                prefixIcon: Icon(Icons.calendar_month),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _dataColheitaPrevistaController,
                              readOnly: true,
                              onTap: () {
                                _selecionarData(
                                  _dataColheitaPrevistaController,
                                );
                              },
                              decoration: const InputDecoration(
                                labelText: 'Colheita prevista',
                                hintText: 'Selecione a data',
                                prefixIcon: Icon(Icons.event_available),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _producaoEstimadaController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Produção estimada',
                                prefixIcon: Icon(Icons.bar_chart),
                              ),
                            ),

                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              value: _statusSafra,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                prefixIcon: Icon(Icons.flag),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Planejada',
                                  child: Text('Planejada'),
                                ),
                                DropdownMenuItem(
                                  value: 'Em andamento',
                                  child: Text('Em andamento'),
                                ),
                                DropdownMenuItem(
                                  value: 'Colhida',
                                  child: Text('Colhida'),
                                ),
                                DropdownMenuItem(
                                  value: 'Cancelada',
                                  child: Text('Cancelada'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _statusSafra = value!;
                                });
                              },
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _observacaoSafraController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Observação',
                                prefixIcon: Icon(Icons.description),
                              ),
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _salvarSafra,
                                child: Text(
                                  _editandoSafra
                                      ? 'Salvar Alterações'
                                      : 'Salvar Safra',
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _cancelarFormularioSafra,
                                child: const Text('Cancelar'),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          if (_safras.isEmpty)
                            const Text(
                              'Nenhuma safra cadastrada para este talhão.',
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _safras.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final safra = _safras[index];

                                return ListTile(
                                  leading: const Icon(
                                    Icons.grass,
                                    color: Color(0xFF064E2F),
                                  ),
                                  title: Text(safra.nome),
                                  subtitle: Text(
                                    'Cultura: ${safra.cultura} | Status: ${safra.status}',
                                  ),
                                  trailing: Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          _editarSafra(safra);
                                        },
                                        child: const Text('Editar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _excluirSafra(safra);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
