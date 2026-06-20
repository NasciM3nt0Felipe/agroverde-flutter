import 'package:flutter/material.dart';

import 'plantio_page.dart';
import 'fertilizacao_page.dart';
import 'pulverizacao_page.dart';
import '../theme/app_theme.dart';
import '../domain/entities/talhao.dart';
import '../domain/entities/safra.dart';
import '../domain/services/sessao_service.dart';
import '../domain/services/talhao_service.dart';
import '../domain/services/safra_service.dart';
import '../domain/services/estoque_service.dart';

class TalhoesSafrasPage extends StatefulWidget {
  const TalhoesSafrasPage({super.key});

  @override
  State<TalhoesSafrasPage> createState() => _TalhoesSafrasPageState();
}

class _TalhoesSafrasPageState extends State<TalhoesSafrasPage> {
  final _formKey = GlobalKey<FormState>();

  final TalhaoService _talhaoService = TalhaoService();
  final SafraService _safraService = SafraService();
  final EstoqueService _estoqueService = EstoqueService();

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

  Talhao? _talhaoSelecionado;

  bool _mostrarFormulario = false;
  bool _editando = false;
  int? _talhaoEditandoId;

  bool _mostrarFormularioSafra = false;
  bool _editandoSafra = false;
  int? _safraEditandoId;

  String _statusSafra = 'Planejada';

  /// Erro específico do campo de área do talhão.
  ///
  /// Usado para exibir no próprio TextFormField quando a regra
  /// de área total da propriedade for violada.
  String? _erroAreaTalhao;

  /// Erro específico do formulário de safra.
  ///
  /// Usado para exibir um aviso visual quando a regra de negócio
  /// impedir o cadastro/edição, como no caso de já existir safra ativa.
  String? _erroSafra;

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
    setState(() {
      _erroAreaTalhao = null;
    });

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

      final mensagem = e.toString().replaceAll('Exception: ', '');

      setState(() {
        _erroAreaTalhao = mensagem;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  Future<void> _salvarSafra() async {
    setState(() {
      _erroSafra = null;
    });

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

      final mensagem = e.toString().replaceAll('Exception: ', '');

      setState(() {
        _erroSafra = mensagem;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
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
      _erroAreaTalhao = null;
    });
  }

  void _abrirFormularioSafra() {
    _limparCamposSafra();

    setState(() {
      _mostrarFormularioSafra = true;
      _editandoSafra = false;
      _safraEditandoId = null;
      _statusSafra = 'Planejada';
      _erroSafra = null;
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
      _erroAreaTalhao = null;
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
      _erroSafra = null;
    });
  }

  void _selecionarTalhao(Talhao talhao) async {
    setState(() {
      _talhaoSelecionado = talhao;
      _mostrarFormularioSafra = false;
      _erroSafra = null;
    });

    await _carregarSafras(talhao.id!);
  }

  void _cancelarFormulario() {
    _limparCampos();

    setState(() {
      _mostrarFormulario = false;
      _editando = false;
      _talhaoEditandoId = null;
      _erroAreaTalhao = null;
    });
  }

  void _cancelarFormularioSafra() {
    _limparCamposSafra();

    setState(() {
      _mostrarFormularioSafra = false;
      _editandoSafra = false;
      _safraEditandoId = null;
      _statusSafra = 'Planejada';
      _erroSafra = null;
    });
  }

  void _limparCampos() {
    _nomeController.clear();
    _areaController.clear();
    _tipoSoloController.clear();
    _observacaoController.clear();
    _erroAreaTalhao = null;
  }

  void _limparCamposSafra() {
    _nomeSafraController.clear();
    _culturaController.clear();
    _variedadeController.clear();
    _dataPlantioController.clear();
    _dataColheitaPrevistaController.clear();
    _producaoEstimadaController.clear();
    _observacaoSafraController.clear();
    _erroSafra = null;
  }

  bool _talhaoEstaSelecionado(Talhao talhao) {
    return _talhaoSelecionado?.id == talhao.id;
  }

  /// Busca o último consumo de sementes da safra.
  ///
  /// Usado para exibir no resumo operacional:
  /// Plantio - Item | Quantidade unidade | Data
  Future<Map<String, dynamic>?> _plantioResumo(Safra safra) async {
    if (safra.id == null) {
      return null;
    }

    return await _estoqueService.buscarUltimoConsumoPorCategoria(
      safraId: safra.id!,
      categoria: 'sementes',
    );
  }

  /// Busca o último consumo de fertilizantes da safra.
  ///
  /// Usado para exibir no resumo operacional:
  /// Fertilização - Item | Quantidade unidade | Data
  Future<Map<String, dynamic>?> _fertilizacaoResumo(Safra safra) async {
    if (safra.id == null) {
      return null;
    }

    return await _estoqueService.buscarUltimoConsumoPorCategoria(
      safraId: safra.id!,
      categoria: 'fertilizantes',
    );
  }

  /// Busca o último consumo de defensivos da safra.
  ///
  /// Usado para exibir no resumo operacional:
  /// Pulverização - Item | Quantidade unidade | Data
  Future<Map<String, dynamic>?> _pulverizacaoResumo(Safra safra) async {
    if (safra.id == null) {
      return null;
    }

    return await _estoqueService.buscarUltimoConsumoPorCategoria(
      safraId: safra.id!,
      categoria: 'defensivos',
    );
  }

  /// Formata a data ISO gravada no banco para dd/MM/yyyy.
  String _formatarDataMovimentacao(dynamic valor) {
    if (valor == null) {
      return '';
    }

    final texto = valor.toString();

    try {
      final data = DateTime.parse(texto);
      final dia = data.day.toString().padLeft(2, '0');
      final mes = data.month.toString().padLeft(2, '0');
      final ano = data.year.toString();

      return '$dia/$mes/$ano';
    } catch (_) {
      if (texto.length >= 10 && texto.contains('-')) {
        final partes = texto.substring(0, 10).split('-');

        if (partes.length == 3) {
          return '${partes[2]}/${partes[1]}/${partes[0]}';
        }
      }

      return texto;
    }
  }

  /// Formata a quantidade evitando casas decimais desnecessárias.
  String _formatarQuantidade(dynamic valor) {
    final numero = double.tryParse(valor.toString());

    if (numero == null) {
      return valor.toString();
    }

    if (numero % 1 == 0) {
      return numero.toInt().toString();
    }

    return numero.toStringAsFixed(2).replaceAll('.', ',');
  }

  /// Monta a linha exibida no resumo operacional.
  Widget _linhaResumoOperacional({
    required IconData icone,
    required String titulo,
    required Map<String, dynamic>? dados,
  }) {
    final realizado = dados != null;

    String texto;

    if (!realizado) {
      texto = '$titulo: Pendente';
    } else {
      final nome = dados['nome']?.toString() ?? 'Item não informado';
      final quantidade = _formatarQuantidade(
        dados['quantidade_utilizada'] ?? 0,
      );
      final unidade = dados['unidade_medida']?.toString() ?? '';
      final data = _formatarDataMovimentacao(dados['data_movimentacao']);

      texto = '$titulo - $nome | $quantidade $unidade';

      if (data.isNotEmpty) {
        texto = '$texto | $data';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icone,
            size: 18,
            color: realizado ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  /// Abre a tela de plantio vinculada à safra selecionada.
  ///
  /// A Page apenas navega e atualiza a interface após o retorno.
  /// A regra de baixa de sementes e registro em estoque_insumo
  /// permanece concentrada no EstoqueService.
  Future<void> _abrirPlantio(Safra safra) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PlantioPage(safra: safra)),
    );

    if (!mounted) return;

    if (resultado == true) {
      if (_talhaoSelecionado?.id != null) {
        await _carregarSafras(_talhaoSelecionado!.id!);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plantio da safra ${safra.nome} registrado.')),
      );
    }
  }

  /// Abre a tela de fertilização vinculada à safra selecionada.
  ///
  /// A Page apenas navega e atualiza a interface após o retorno.
  /// A regra de baixa de fertilizantes e registro em estoque_insumo
  /// permanece concentrada no EstoqueService.
  Future<void> _abrirFertilizacao(Safra safra) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FertilizacaoPage(safra: safra)),
    );

    if (!mounted) return;

    if (resultado == true) {
      if (_talhaoSelecionado?.id != null) {
        await _carregarSafras(_talhaoSelecionado!.id!);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fertilização da safra ${safra.nome} registrada.'),
        ),
      );
    }
  }

  /// Abre a tela de pulverização vinculada à safra selecionada.
  ///
  /// A Page apenas navega e atualiza a interface após o retorno.
  /// A regra de baixa de defensivos e registro em estoque_insumo
  /// permanece concentrada no EstoqueService.
  Future<void> _abrirPulverizacao(Safra safra) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PulverizacaoPage(safra: safra)),
    );

    if (!mounted) return;

    if (resultado == true) {
      if (_talhaoSelecionado?.id != null) {
        await _carregarSafras(_talhaoSelecionado!.id!);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pulverização da safra ${safra.nome} registrada.'),
        ),
      );
    }
  }

  /// Cria um botão responsivo para as ações operacionais da safra.
  ///
  /// O Wrap usado na listagem permite que esses botões fiquem lado a lado
  /// no desktop e quebrem linha automaticamente em telas menores.
  Widget _botaoAcaoSafra({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 190,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(14),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(icone, color: AppTheme.primaryGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Monta o card de uma safra com ações operacionais.
  ///
  /// Aqui fica apenas a composição visual.
  /// As regras de negócio de plantio, fertilização, pulverização e colheita
  /// serão implementadas nos services específicos.
  Widget _buildSafraCard(Safra safra) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.grass, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safra.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cultura: ${safra.cultura}'
                        '${safra.variedade == null || safra.variedade!.isEmpty ? '' : ' | Variedade: ${safra.variedade}'}'
                        ' | Status: ${safra.status}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Plantio: ${safra.dataPlantio}'
                        '${safra.dataColheitaPrevista == null || safra.dataColheitaPrevista!.isEmpty ? '' : ' | Colheita prevista: ${safra.dataColheitaPrevista}'}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
              ],
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<Map<String, dynamic>?>>(
              future: Future.wait([
                _plantioResumo(safra),
                _fertilizacaoResumo(safra),
                _pulverizacaoResumo(safra),
              ]),
              builder: (context, snapshot) {
                final dados = snapshot.data ?? [null, null, null];

                final plantio = dados[0];
                final fertilizacao = dados[1];
                final pulverizacao = dados[2];

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo Operacional',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _linhaResumoOperacional(
                        icone: Icons.spa,
                        titulo: 'Plantio',
                        dados: plantio,
                      ),
                      _linhaResumoOperacional(
                        icone: Icons.science,
                        titulo: 'Fertilização',
                        dados: fertilizacao,
                      ),
                      _linhaResumoOperacional(
                        icone: Icons.bug_report,
                        titulo: 'Pulverização',
                        dados: pulverizacao,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Ações da safra',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _botaoAcaoSafra(
                  icone: Icons.spa,
                  titulo: 'Plantio',
                  subtitulo: 'Registrar sementes',
                  onTap: () => _abrirPlantio(safra),
                ),
                _botaoAcaoSafra(
                  icone: Icons.science,
                  titulo: 'Fertilização',
                  subtitulo: 'Aplicar fertilizantes',
                  onTap: () => _abrirFertilizacao(safra),
                ),
                _botaoAcaoSafra(
                  icone: Icons.bug_report,
                  titulo: 'Pulverização',
                  subtitulo: 'Controle de pragas',
                  onTap: () => _abrirPulverizacao(safra),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                              decoration: InputDecoration(
                                labelText: 'Área do talhão (hectares)',
                                prefixIcon: const Icon(Icons.square_foot),
                                errorText: _erroAreaTalhao,
                              ),
                              onChanged: (_) {
                                if (_erroAreaTalhao != null) {
                                  setState(() {
                                    _erroAreaTalhao = null;
                                  });
                                }
                              },
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
                                      : AppTheme.primaryGreen,
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
                                            ? AppTheme.primaryGreen
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

                            if (_erroSafra != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _erroSafra!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

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
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final safra = _safras[index];

                                return _buildSafraCard(safra);
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
