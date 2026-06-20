import 'package:flutter/material.dart';

import '../domain/entities/safra.dart';
import '../domain/entities/estoque_item.dart';
import '../domain/services/estoque_service.dart';
import '../domain/services/sessao_service.dart';
import '../theme/app_theme.dart';

class FertilizacaoPage extends StatefulWidget {
  final Safra safra;

  const FertilizacaoPage({super.key, required this.safra});

  @override
  State<FertilizacaoPage> createState() => _FertilizacaoPageState();
}

class _FertilizacaoPageState extends State<FertilizacaoPage> {
  final _formKey = GlobalKey<FormState>();

  final EstoqueService _estoqueService = EstoqueService();

  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  List<EstoqueItem> _fertilizantes = [];
  EstoqueItem? _fertilizanteSelecionado;

  bool _carregando = true;
  bool _salvando = false;
  String? _erroFertilizacao;

  @override
  void initState() {
    super.initState();
    _carregarFertilizantes();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  /// Carrega somente itens da categoria Fertilizantes
  /// que possuem saldo disponível no estoque.
  Future<void> _carregarFertilizantes() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      setState(() {
        _carregando = false;
        _erroFertilizacao = 'Selecione uma propriedade em foco primeiro.';
      });
      return;
    }

    final itens = await _estoqueService.listarPorPropriedadeId(propriedadeId);

    final fertilizantes = itens.where((item) {
      return item.categoria.trim().toLowerCase() == 'fertilizantes' &&
          item.quantidadeAtual > 0;
    }).toList();

    setState(() {
      _fertilizantes = fertilizantes;
      _carregando = false;
    });
  }

  /// Registra a fertilização da safra.
  ///
  /// A Page valida os campos e envia os dados para o EstoqueService.
  /// O service fica responsável por validar saldo, baixar estoque
  /// e registrar o consumo em estoque_insumo.
  Future<void> _registrarFertilizacao() async {
    setState(() {
      _erroFertilizacao = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.safra.id == null) {
      setState(() {
        _erroFertilizacao = 'Safra inválida para registrar fertilização.';
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
        estoqueItemId: _fertilizanteSelecionado!.id!,
        quantidade: quantidade,
        observacao: _observacaoController.text.trim().isEmpty
            ? 'Fertilização da safra ${widget.safra.nome}'
            : _observacaoController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fertilização registrada com sucesso!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _erroFertilizacao = e.toString().replaceAll('Exception: ', '');
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
      appBar: AppBar(title: const Text('Registrar Fertilização')),
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
                          Icons.science,
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
                                  'Dados da fertilização',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_erroFertilizacao != null) ...[
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
                                            _erroFertilizacao!,
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
                                  value: _fertilizanteSelecionado,
                                  decoration: const InputDecoration(
                                    labelText: 'Fertilizante',
                                    prefixIcon: Icon(Icons.science),
                                  ),
                                  items: _fertilizantes.map((item) {
                                    return DropdownMenuItem<EstoqueItem>(
                                      value: item,
                                      child: Text(
                                        '${item.nome} - ${item.quantidadeAtual} ${item.unidadeMedida}',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _fertilizanteSelecionado = value;
                                      _erroFertilizacao = null;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Selecione um fertilizante.';
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
                                        : _registrarFertilizacao,
                                    icon: const Icon(Icons.check),
                                    label: Text(
                                      _salvando
                                          ? 'Registrando...'
                                          : 'Registrar Fertilização',
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
