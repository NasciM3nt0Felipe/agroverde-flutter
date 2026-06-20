import 'package:flutter/material.dart';

import '../domain/entities/safra.dart';
import '../domain/entities/estoque_item.dart';
import '../domain/services/estoque_service.dart';
import '../domain/services/sessao_service.dart';
import '../theme/app_theme.dart';

class PulverizacaoPage extends StatefulWidget {
  final Safra safra;

  const PulverizacaoPage({super.key, required this.safra});

  @override
  State<PulverizacaoPage> createState() => _PulverizacaoPageState();
}

class _PulverizacaoPageState extends State<PulverizacaoPage> {
  final _formKey = GlobalKey<FormState>();

  final EstoqueService _estoqueService = EstoqueService();

  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  List<EstoqueItem> _defensivos = [];
  EstoqueItem? _defensivoSelecionado;

  bool _carregando = true;
  bool _salvando = false;
  String? _erroPulverizacao;

  @override
  void initState() {
    super.initState();
    _carregarDefensivos();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  /// Carrega somente itens da categoria Defensivos
  /// que possuem saldo disponível no estoque.
  Future<void> _carregarDefensivos() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      setState(() {
        _carregando = false;
        _erroPulverizacao = 'Selecione uma propriedade em foco primeiro.';
      });
      return;
    }

    final itens = await _estoqueService.listarPorPropriedadeId(propriedadeId);

    final defensivos = itens.where((item) {
      return item.categoria.trim().toLowerCase() == 'defensivos' &&
          item.quantidadeAtual > 0;
    }).toList();

    setState(() {
      _defensivos = defensivos;
      _carregando = false;
    });
  }

  /// Registra a pulverização da safra.
  ///
  /// A Page valida os campos e envia os dados para o EstoqueService.
  /// O service fica responsável por validar saldo, baixar estoque
  /// e registrar o consumo em estoque_insumo.
  Future<void> _registrarPulverizacao() async {
    setState(() {
      _erroPulverizacao = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.safra.id == null) {
      setState(() {
        _erroPulverizacao = 'Safra inválida para registrar pulverização.';
      });
      return;
    }

    final quantidade = double.parse(
      _quantidadeController.text.replaceAll(',', '.'),
    );

    try {
      setState(() {
        _salvando = true;
      });

      await _estoqueService.registrarConsumoSafra(
        safraId: widget.safra.id!,
        estoqueItemId: _defensivoSelecionado!.id!,
        quantidade: quantidade,
        observacao: _observacaoController.text.trim().isEmpty
            ? 'Pulverização da safra ${widget.safra.nome}'
            : _observacaoController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pulverização registrada com sucesso!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _erroPulverizacao = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propriedadeNome = SessaoService.propriedadeNome;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Pulverização')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bug_report,
                          color: AppTheme.primaryGreen,
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.safra.nome,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Cultura: ${widget.safra.cultura}'),
                              if (propriedadeNome != null)
                                Text('Propriedade: $propriedadeNome'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _carregando
                        ? const Center(child: CircularProgressIndicator())
                        : Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Dados da pulverização',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_erroPulverizacao != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(color: Colors.red),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _erroPulverizacao!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                DropdownButtonFormField<EstoqueItem>(
                                  value: _defensivoSelecionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Defensivo',
                                    prefixIcon: Icon(Icons.bug_report),
                                  ),
                                  items: _defensivos.map((item) {
                                    return DropdownMenuItem<EstoqueItem>(
                                      value: item,
                                      child: Text(
                                        '${item.nome} - ${item.quantidadeAtual} ${item.unidadeMedida}',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _defensivoSelecionado = value;
                                      _erroPulverizacao = null;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Selecione um defensivo.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _quantidadeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantidade utilizada',
                                    prefixIcon: Icon(Icons.scale),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe a quantidade utilizada.';
                                    }

                                    final quantidade = double.tryParse(
                                      value.replaceAll(',', '.'),
                                    );

                                    if (quantidade == null || quantidade <= 0) {
                                      return 'Informe uma quantidade válida.';
                                    }

                                    return null;
                                  },
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
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _salvando
                                        ? null
                                        : _registrarPulverizacao,
                                    icon: const Icon(Icons.check),
                                    label: Text(
                                      _salvando
                                          ? 'Registrando...'
                                          : 'Registrar Pulverização',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: _salvando
                                        ? null
                                        : () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                              ],
                            ),
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
