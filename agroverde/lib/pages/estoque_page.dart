import 'package:flutter/material.dart';

import '../domain/entities/estoque_item.dart';
import '../domain/services/estoque_service.dart';
import '../domain/services/sessao_service.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  final _formKey = GlobalKey<FormState>();

  final EstoqueService _estoqueService = EstoqueService();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _quantidadeInicialController =
      TextEditingController();
  final TextEditingController _quantidadeAtualController =
      TextEditingController();
  final TextEditingController _precoMedioController = TextEditingController();
  final TextEditingController _estoqueMinimoController =
      TextEditingController();
  final TextEditingController _fornecedorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _buscaController = TextEditingController();

  List<EstoqueItem> _itens = [];

  bool _mostrarFormulario = false;
  bool _editando = false;
  int? _itemEditandoId;

  String _categoria = 'Sementes';
  String _unidadeMedida = 'Kg';

  /// Categoria escolhida para consulta.
  ///
  /// Começa nula para evitar carregar/listar todo o estoque
  /// ao abrir a página.
  String? _categoriaFiltro;

  final List<String> _categorias = const [
    'Sementes',
    'Fertilizantes',
    'Defensivos',
    'Ração',
    'Vacinas',
    'Medicamentos',
    'Ferramentas',
    'Outros',
  ];

  final List<String> _unidades = const [
    'Kg',
    'g',
    'Litros',
    'mL',
    'Sacas',
    'Unidades',
    'Doses',
    'Toneladas',
  ];

  @override
  void initState() {
    super.initState();

    /// Não carregamos os itens automaticamente ao abrir a página.
    ///
    /// O carregamento só acontece após o usuário escolher uma categoria.
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeInicialController.dispose();
    _quantidadeAtualController.dispose();
    _precoMedioController.dispose();
    _estoqueMinimoController.dispose();
    _fornecedorController.dispose();
    _observacaoController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  /// Carrega os itens de estoque da propriedade.
  Future<void> _carregarEstoque() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      return;
    }

    final lista = await _estoqueService.listarPorPropriedadeId(propriedadeId);

    setState(() {
      _itens = lista;
    });
  }

  /// Aplica os filtros de categoria e pesquisa.
  List<EstoqueItem> get _itensFiltrados {
    if (_categoriaFiltro == null) {
      return [];
    }

    return _estoqueService.filtrarItens(
      itens: _itens,
      categoria: _categoriaFiltro!,
      busca: _buscaController.text,
    );
  }

  /// Carrega os itens da categoria selecionada.
  Future<void> _selecionarCategoriaFiltro(String? categoria) async {
    setState(() {
      _categoriaFiltro = categoria;
      _buscaController.clear();
    });

    await _carregarEstoque();
  }

  void _limparPesquisa() {
    setState(() {
      _buscaController.clear();
    });
  }

  /// Salva ou atualiza um item de estoque.
  Future<void> _salvarItem() async {
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

    final item = EstoqueItem(
      id: _itemEditandoId,
      propriedadeId: propriedadeId,
      nome: _nomeController.text.trim(),
      categoria: _categoria,
      quantidadeInicial: double.parse(
        _quantidadeInicialController.text.replaceAll(',', '.'),
      ),
      quantidadeAtual: double.parse(
        _quantidadeAtualController.text.replaceAll(',', '.'),
      ),
      unidadeMedida: _unidadeMedida,
      precoMedioUnitario: double.parse(
        _precoMedioController.text.replaceAll(',', '.'),
      ),
      estoqueMinimo: double.parse(
        _estoqueMinimoController.text.replaceAll(',', '.'),
      ),
      fornecedor: _fornecedorController.text.trim(),
      observacao: _observacaoController.text.trim(),
    );

    try {
      await _estoqueService.salvar(item);
      await _carregarEstoque();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editando
                ? 'Item atualizado com sucesso!'
                : 'Item cadastrado com sucesso!',
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

  Future<void> _excluirItem(EstoqueItem item) async {
    await _estoqueService.excluir(item.id!);
    await _carregarEstoque();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item excluído com sucesso!')));
  }

  void _abrirFormularioCadastro() {
    _limparCampos();

    setState(() {
      _mostrarFormulario = true;
      _editando = false;
      _itemEditandoId = null;
      _categoria = 'Sementes';
      _unidadeMedida = 'Kg';
    });
  }

  /// Preenche o formulário para edição do item.
  void _editarItem(EstoqueItem item) {
    _nomeController.text = item.nome;
    _quantidadeInicialController.text = item.quantidadeInicial.toString();
    _quantidadeAtualController.text = item.quantidadeAtual.toString();
    _precoMedioController.text = item.precoMedioUnitario.toString();
    _estoqueMinimoController.text = item.estoqueMinimo.toString();
    _fornecedorController.text = item.fornecedor ?? '';
    _observacaoController.text = item.observacao ?? '';

    setState(() {
      _mostrarFormulario = true;
      _editando = true;
      _itemEditandoId = item.id;
      _categoria = item.categoria;
      _unidadeMedida = item.unidadeMedida;
    });
  }

  void _cancelarFormulario() {
    _limparCampos();

    setState(() {
      _mostrarFormulario = false;
      _editando = false;
      _itemEditandoId = null;
      _categoria = 'Sementes';
      _unidadeMedida = 'Kg';
    });
  }

  void _limparCampos() {
    _nomeController.clear();
    _quantidadeInicialController.clear();
    _quantidadeAtualController.clear();
    _precoMedioController.clear();
    _estoqueMinimoController.clear();
    _fornecedorController.clear();
    _observacaoController.clear();
  }

  String _statusEstoque(EstoqueItem item) {
    if (item.estoqueZerado) {
      return 'Zerado';
    }

    if (item.estoqueBaixo) {
      return 'Baixo';
    }

    return 'Normal';
  }

  Color _corStatus(EstoqueItem item) {
    if (item.estoqueZerado) {
      return Colors.red;
    }

    if (item.estoqueBaixo) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final propriedadeNome = SessaoService.propriedadeNome;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 1000,
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
                      label: const Text('Novo Item'),
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
                                  ? 'Editar Item de Estoque'
                                  : 'Cadastro de Item de Estoque',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome do item',
                                prefixIcon: Icon(Icons.inventory),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome do item';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: _categoria,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: _categorias
                                  .map(
                                    (categoria) => DropdownMenuItem(
                                      value: categoria,
                                      child: Text(categoria),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _categoria = value!;
                                });
                              },
                            ),

                            const SizedBox(height: 16),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 650;

                                final quantidadeInicial = TextFormField(
                                  controller: _quantidadeInicialController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantidade inicial',
                                    prefixIcon: Icon(Icons.add_box),
                                  ),
                                  validator: _validarNumeroObrigatorio,
                                );

                                final quantidadeAtual = TextFormField(
                                  controller: _quantidadeAtualController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantidade atual',
                                    prefixIcon: Icon(Icons.inventory_2),
                                  ),
                                  validator: _validarNumeroObrigatorio,
                                );

                                if (isWide) {
                                  return Row(
                                    children: [
                                      Expanded(child: quantidadeInicial),
                                      const SizedBox(width: 16),
                                      Expanded(child: quantidadeAtual),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    quantidadeInicial,
                                    const SizedBox(height: 16),
                                    quantidadeAtual,
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth > 650;

                                final unidadeMedida =
                                    DropdownButtonFormField<String>(
                                      value: _unidadeMedida,
                                      decoration: const InputDecoration(
                                        labelText: 'Unidade de medida',
                                        prefixIcon: Icon(Icons.straighten),
                                      ),
                                      items: _unidades
                                          .map(
                                            (unidade) => DropdownMenuItem(
                                              value: unidade,
                                              child: Text(unidade),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _unidadeMedida = value!;
                                        });
                                      },
                                    );

                                final precoMedio = TextFormField(
                                  controller: _precoMedioController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Preço médio por $_unidadeMedida',
                                    prefixIcon: const Icon(Icons.attach_money),
                                  ),
                                  validator: _validarNumeroObrigatorio,
                                );

                                if (isWide) {
                                  return Row(
                                    children: [
                                      Expanded(child: unidadeMedida),
                                      const SizedBox(width: 16),
                                      Expanded(child: precoMedio),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    unidadeMedida,
                                    const SizedBox(height: 16),
                                    precoMedio,
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _estoqueMinimoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Estoque mínimo',
                                prefixIcon: Icon(Icons.warning),
                              ),
                              validator: _validarNumeroObrigatorio,
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _fornecedorController,
                              decoration: const InputDecoration(
                                labelText: 'Fornecedor',
                                prefixIcon: Icon(Icons.store),
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
                                onPressed: _salvarItem,
                                child: Text(
                                  _editando
                                      ? 'Salvar Alterações'
                                      : 'Salvar Item',
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
                          'Itens em estoque',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 700;

                            final filtroCategoria =
                                DropdownButtonFormField<String>(
                                  value: _categoriaFiltro,
                                  decoration: const InputDecoration(
                                    labelText: 'Categoria',
                                    prefixIcon: Icon(Icons.category),
                                  ),
                                  hint: const Text('Selecione uma categoria'),
                                  items: _categorias
                                      .map(
                                        (categoria) => DropdownMenuItem(
                                          value: categoria,
                                          child: Text(categoria),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: _selecionarCategoriaFiltro,
                                );

                            final campoBusca = TextFormField(
                              controller: _buscaController,
                              enabled: _categoriaFiltro != null,
                              decoration: InputDecoration(
                                labelText: 'Pesquisar',
                                hintText: _categoriaFiltro == null
                                    ? 'Selecione uma categoria primeiro'
                                    : 'Ex: NPK, ração, vacina...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _buscaController.text.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Limpar pesquisa',
                                        onPressed: _limparPesquisa,
                                        icon: const Icon(Icons.clear),
                                      )
                                    : null,
                              ),
                              onChanged: (_) {
                                setState(() {});
                              },
                            );

                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(child: filtroCategoria),
                                  const SizedBox(width: 16),
                                  Expanded(child: campoBusca),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                filtroCategoria,
                                const SizedBox(height: 16),
                                campoBusca,
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _categoriaFiltro == null
                              ? 'Nenhuma categoria selecionada.'
                              : 'Exibindo ${_itensFiltrados.length} item(ns) da categoria $_categoriaFiltro',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 16),

                        if (SessaoService.propriedadeId == null)
                          const Text(
                            'Selecione uma propriedade em foco para gerenciar o estoque.',
                          )
                        else if (_categoriaFiltro == null)
                          const Text(
                            'Selecione uma categoria para visualizar os itens.',
                          )
                        else if (_itensFiltrados.isEmpty)
                          const Text(
                            'Nenhum item encontrado para esta categoria.',
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _itensFiltrados.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final item = _itensFiltrados[index];

                              return ListTile(
                                leading: Icon(
                                  Icons.inventory,
                                  color: _corStatus(item),
                                ),
                                title: Text(item.nome),
                                subtitle: Text(
                                  '${item.categoria} | '
                                  '${item.quantidadeAtual} ${item.unidadeMedida} | '
                                  '${_formatarMoeda(item.valorTotal)} | '
                                  'Status: ${_statusEstoque(item)}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        _editarItem(item);
                                      },
                                      child: const Text('Editar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _excluirItem(item);
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validarNumeroObrigatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }

    final numero = double.tryParse(value.replaceAll(',', '.'));

    if (numero == null || numero < 0) {
      return 'Informe um número válido';
    }

    return null;
  }
}
