import 'package:flutter/material.dart';

import '../domain/entities/safra.dart';
import '../domain/entities/estoque_item.dart';
import '../domain/services/estoque_service.dart';
import '../domain/services/sessao_service.dart';
import '../theme/app_theme.dart';

class PlantioPage extends StatefulWidget {
  final Safra safra;

  const PlantioPage({super.key, required this.safra});

  @override
  State<PlantioPage> createState() => _PlantioPageState();
}

class _PlantioPageState extends State<PlantioPage> {
  final _formKey = GlobalKey<FormState>();

  final EstoqueService _estoqueService = EstoqueService();

  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  List<EstoqueItem> _sementes = [];
  EstoqueItem? _sementeSelecionada;

  bool _carregando = true;
  bool _salvando = false;
  String? _erroPlantio;

  @override
  void initState() {
    super.initState();
    _carregarSementes();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarSementes() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      setState(() {
        _carregando = false;
        _erroPlantio = 'Selecione uma propriedade em foco primeiro.';
      });
      return;
    }

    final itens = await _estoqueService.listarPorPropriedadeId(propriedadeId);

    final sementes = itens.where((item) {
      return item.categoria.trim().toLowerCase() == 'sementes' &&
          item.quantidadeAtual > 0;
    }).toList();

    setState(() {
      _sementes = sementes;
      _carregando = false;
    });
  }

  Future<void> _registrarPlantio() async {
    setState(() {
      _erroPlantio = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.safra.id == null) {
      setState(() {
        _erroPlantio = 'Safra inválida para registrar plantio.';
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
        estoqueItemId: _sementeSelecionada!.id!,
        quantidade: quantidade,
        observacao: _observacaoController.text.trim().isEmpty
            ? 'Plantio da safra ${widget.safra.nome}'
            : _observacaoController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantio registrado com sucesso!')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _erroPlantio = e.toString().replaceAll('Exception: ', '');
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
      appBar: AppBar(title: const Text('Registrar Plantio')),
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
                          Icons.spa,
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
                                  'Dados do plantio',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_erroPlantio != null) ...[
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
                                            _erroPlantio!,
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
                                  value: _sementeSelecionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Semente',
                                    prefixIcon: Icon(Icons.grass),
                                  ),
                                  items: _sementes.map((item) {
                                    return DropdownMenuItem<EstoqueItem>(
                                      value: item,
                                      child: Text(
                                        '${item.nome} - ${item.quantidadeAtual} ${item.unidadeMedida}',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _sementeSelecionada = value;
                                      _erroPlantio = null;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Selecione uma semente.';
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
                                        : _registrarPlantio,
                                    icon: const Icon(Icons.check),
                                    label: Text(
                                      _salvando
                                          ? 'Registrando...'
                                          : 'Registrar Plantio',
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
