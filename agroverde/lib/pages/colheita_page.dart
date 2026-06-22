import 'package:flutter/material.dart';

import '../data/sqlite/safra_repository.dart';
import '../domain/entities/armazenamento_grao.dart';
import '../domain/entities/colheita.dart';
import '../domain/entities/safra.dart';
import '../domain/entities/venda_grao.dart';
import '../domain/services/colheita_service.dart';
import '../domain/services/sessao_service.dart';

class ColheitaPage extends StatefulWidget {
  const ColheitaPage({super.key});

  @override
  State<ColheitaPage> createState() => _ColheitaPageState();
}

class _ColheitaPageState extends State<ColheitaPage> {
  final ColheitaService _service = ColheitaService();
  final SafraRepository _safraRepository = SafraRepository();

  final _quantidadeColhidaController = TextEditingController();
  final _observacaoColheitaController = TextEditingController();

  final _quantidadeVendaController = TextEditingController();
  final _valorUnitarioController = TextEditingController();
  final _compradorController = TextEditingController();
  final _observacaoVendaController = TextEditingController();

  String _unidadeColheita = 'Sacas';
  String _unidadeVenda = 'Sacas';

  Safra? _safraSelecionada;

  List<Safra> _safrasDisponiveis = [];
  List<Colheita> _colheitas = [];
  List<ArmazenamentoGrao> _armazenamentos = [];
  List<VendaGrao> _vendas = [];

  bool _carregando = false;
  String? _erroColheita;

  double get totalArmazenado {
    return _armazenamentos.fold(
      0,
      (total, item) => total + item.quantidadeDisponivel,
    );
  }

  double get totalReceitaVendas {
    return _vendas.fold(0, (total, item) => total + item.valorTotal);
  }

  double get totalQuantidadeVendida {
    return _vendas.fold(0, (total, item) => total + item.quantidadeVendida);
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _quantidadeColhidaController.dispose();
    _observacaoColheitaController.dispose();
    _quantidadeVendaController.dispose();
    _valorUnitarioController.dispose();
    _compradorController.dispose();
    _observacaoVendaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) return;

    setState(() {
      _carregando = true;
    });

    final safras = await _safraRepository
        .listarDisponiveisParaColheitaPorPropriedade(propriedadeId);

    final colheitas = await _service.listarColheitas(propriedadeId);
    final armazenamentos = await _service.listarArmazenamentos(propriedadeId);
    final vendas = await _service.listarVendas(propriedadeId);

    setState(() {
      _safrasDisponiveis = safras;
      _colheitas = colheitas;
      _armazenamentos = armazenamentos;
      _vendas = vendas;

      if (_safraSelecionada != null &&
          !_safrasDisponiveis.any((s) => s.id == _safraSelecionada!.id)) {
        _safraSelecionada = null;
      }

      _carregando = false;
    });
  }

  Future<void> _registrarColheita() async {
    setState(() {
      _erroColheita = null;
    });

    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      _exibirErroColheita('Selecione uma propriedade antes de registrar.');
      return;
    }

    if (_safraSelecionada == null) {
      _exibirErroColheita('Selecione uma safra disponível para colheita.');
      return;
    }

    if (_safraSelecionada!.status.toLowerCase() == 'planejada') {
      _exibirErroColheita(
        'Não é possível colher uma safra sem plantio registrado.',
      );
      return;
    }

    final quantidadeTexto = _quantidadeColhidaController.text.trim().replaceAll(
      ',',
      '.',
    );

    final quantidade = double.tryParse(quantidadeTexto);

    if (quantidade == null || quantidade <= 0) {
      _exibirErroColheita('Informe uma quantidade válida.');
      return;
    }

    try {
      await _service.registrarColheita(
        safraId: _safraSelecionada!.id!,
        propriedadeId: propriedadeId,
        produto: _safraSelecionada!.cultura,
        dataColheita: DateTime.now().toIso8601String(),
        quantidadeProduzida: quantidade,
        unidade: _unidadeColheita,
        observacao: _observacaoColheitaController.text.trim(),
      );

      _limparColheita();
      await _carregarDados();

      _mostrarMensagem('Colheita registrada com sucesso!');
    } catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      _exibirErroColheita(mensagem);
    }
  }

  Future<void> _abrirVenda(ArmazenamentoGrao armazenamento) async {
    _quantidadeVendaController.clear();
    _valorUnitarioController.clear();
    _compradorController.clear();
    _observacaoVendaController.clear();
    _unidadeVenda = armazenamento.unidade;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Vender ${armazenamento.produto}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disponível: ${_formatarNumero(armazenamento.quantidadeDisponivel)} ${armazenamento.unidade}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _quantidadeVendaController,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade vendida',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _valorUnitarioController,
                    decoration: const InputDecoration(
                      labelText: 'Valor por unidade',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _unidadeVenda,
                    decoration: const InputDecoration(
                      labelText: 'Unidade',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Sacas', child: Text('Sacas')),
                      DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _unidadeVenda = value;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _compradorController,
                    decoration: const InputDecoration(
                      labelText: 'Comprador',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _observacaoVendaController,
                    decoration: const InputDecoration(
                      labelText: 'Observação',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _registrarVenda(armazenamento);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Vender'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registrarVenda(ArmazenamentoGrao armazenamento) async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) return;

    final quantidadeTexto = _quantidadeVendaController.text.trim().replaceAll(
      ',',
      '.',
    );

    final valorTexto = _valorUnitarioController.text.trim().replaceAll(
      ',',
      '.',
    );

    final quantidade = double.tryParse(quantidadeTexto);
    final valorUnitario = double.tryParse(valorTexto);

    if (quantidade == null || quantidade <= 0) {
      _mostrarMensagem('Informe uma quantidade válida.');
      return;
    }

    if (valorUnitario == null || valorUnitario <= 0) {
      _mostrarMensagem('Informe um valor unitário válido.');
      return;
    }

    try {
      await _service.registrarVenda(
        armazenamentoId: armazenamento.id!,
        propriedadeId: propriedadeId,
        dataVenda: DateTime.now().toIso8601String(),
        quantidadeVendida: quantidade,
        valorUnitario: valorUnitario,
        unidade: _unidadeVenda,
        comprador: _compradorController.text.trim(),
        observacao: _observacaoVendaController.text.trim(),
      );

      await _carregarDados();
      _mostrarMensagem('Venda registrada com sucesso!');
    } catch (e) {
      _mostrarMensagem('Erro ao registrar venda: $e');
    }
  }

  void _limparColheita() {
    setState(() {
      _safraSelecionada = null;
      _quantidadeColhidaController.clear();
      _observacaoColheitaController.clear();
      _unidadeColheita = 'Sacas';
      _erroColheita = null;
    });
  }

  void _exibirErroColheita(String mensagem) {
    setState(() {
      _erroColheita = mensagem;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(mensagem)),
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  String _formatarData(String data) {
    if (data.length < 10) return data;

    final partes = data.substring(0, 10).split('-');

    if (partes.length != 3) return data;

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatarNumero(double valor) {
    if (valor % 1 == 0) {
      return valor.toStringAsFixed(0);
    }

    return valor.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _produtoDaColheita(Colheita colheita) {
    for (final armazenamento in _armazenamentos) {
      if (armazenamento.colheitaId == colheita.id) {
        return armazenamento.produto;
      }
    }

    return 'Safra ${colheita.safraId}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: const Text('Colheitas'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Colheitas',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        SessaoService.propriedadeNome == null
                            ? 'Selecione uma propriedade para gerenciar colheitas.'
                            : 'Propriedade: ${SessaoService.propriedadeNome}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      _cardsResumo(),
                      const SizedBox(height: 24),
                      _formularioColheita(),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _secaoArmazenamento()),
                          const SizedBox(width: 20),
                          Expanded(child: _historicoVendas()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _historicoColheitas(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _cardsResumo() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _ResumoCard(
          titulo: 'Sacas em Estoque',
          valor: _formatarNumero(totalArmazenado),
          subtitulo: 'Disponível para venda',
          icone: Icons.grass,
          cor: const Color(0xFF0B6B38),
        ),
        _ResumoCard(
          titulo: 'Quantidade Vendida',
          valor: _formatarNumero(totalQuantidadeVendida),
          subtitulo: 'Total registrado',
          icone: Icons.shopping_cart,
          cor: const Color(0xFF0D47A1),
        ),
        _ResumoCard(
          titulo: 'Receita de Vendas',
          valor: _formatarValor(totalReceitaVendas),
          subtitulo: 'Receita gerada no financeiro',
          icone: Icons.attach_money,
          cor: const Color(0xFFB26A00),
        ),
      ],
    );
  }

  Widget _formularioColheita() {
    return _CardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecaoTitulo(
            titulo: 'Registrar Colheita',
            icone: Icons.agriculture,
          ),
          const SizedBox(height: 16),
          if (_safrasDisponiveis.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Nenhuma safra disponível para colheita no momento.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            DropdownButtonFormField<Safra>(
              value: _safraSelecionada,
              decoration: const InputDecoration(
                labelText: 'Safra disponível para colheita',
                border: OutlineInputBorder(),
              ),
              items: _safrasDisponiveis.map((safra) {
                return DropdownMenuItem<Safra>(
                  value: safra,
                  child: Text(
                    '${safra.nome} - ${safra.cultura} | Prevista: ${_formatarData(safra.dataColheitaPrevista ?? '')}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _safraSelecionada = value;
                });
              },
            ),
          const SizedBox(height: 12),
          if (_erroColheita != null) ...[
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
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _erroColheita!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _quantidadeColhidaController,
                  enabled: _safrasDisponiveis.isNotEmpty,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade produzida',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  value: _unidadeColheita,
                  decoration: const InputDecoration(
                    labelText: 'Unidade',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Sacas', child: Text('Sacas')),
                    DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                  ],
                  onChanged: _safrasDisponiveis.isEmpty
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _unidadeColheita = value;
                            });
                          }
                        },
                ),
              ),
              SizedBox(
                width: 420,
                child: TextField(
                  controller: _observacaoColheitaController,
                  enabled: _safrasDisponiveis.isNotEmpty,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E2F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            ),
            onPressed: _safrasDisponiveis.isEmpty ? null : _registrarColheita,
            icon: const Icon(Icons.agriculture),
            label: const Text('Colher Safra'),
          ),
        ],
      ),
    );
  }

  Widget _secaoArmazenamento() {
    final armazenamentosDisponiveis = _armazenamentos
        .where((item) => item.quantidadeDisponivel > 0)
        .toList();
    return _CardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecaoTitulo(titulo: 'Armazenamento', icone: Icons.inventory_2),
          const SizedBox(height: 12),
          if (armazenamentosDisponiveis.isEmpty)
            const Text('Nenhum grão armazenado.')
          else
            ...armazenamentosDisponiveis.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        item.produto.isEmpty
                            ? '?'
                            : item.produto.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF064E2F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.produto,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Disponível: ${_formatarNumero(item.quantidadeDisponivel)} ${item.unidade}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          Text(
                            'Status: ${item.status}',
                            style: TextStyle(
                              color: item.status == 'Vendido'
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: item.quantidadeDisponivel > 0
                          ? () => _abrirVenda(item)
                          : null,
                      child: const Text('Vender'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _historicoVendas() {
    return _CardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecaoTitulo(
            titulo: 'Histórico de Vendas',
            icone: Icons.receipt_long,
          ),
          const SizedBox(height: 12),
          if (_vendas.isEmpty)
            const Text('Nenhuma venda registrada.')
          else
            ..._vendas.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_formatarNumero(item.quantidadeVendida)} ${item.unidade}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Valor unitário: ${_formatarValor(item.valorUnitario)}\nTotal: ${_formatarValor(item.valorTotal)}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _historicoColheitas() {
    return _CardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SecaoTitulo(
            titulo: 'Histórico de Colheitas',
            icone: Icons.history,
          ),
          const SizedBox(height: 12),
          if (_colheitas.isEmpty)
            const Text('Nenhuma colheita registrada.')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Grão')),
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Produzido')),
                  DataColumn(label: Text('Unidade')),
                ],
                rows: _colheitas.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(Text(_produtoDaColheita(item))),
                      DataCell(Text(_formatarData(item.dataColheita))),
                      DataCell(Text(_formatarNumero(item.quantidadeProduzida))),
                      DataCell(Text(item.unidade)),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;
  final Color cor;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 140,
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: cor.withOpacity(0.12),
                child: Icon(icone, color: cor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(color: cor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBase extends StatelessWidget {
  final Widget child;

  const _CardBase({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final String titulo;
  final IconData icone;

  const _SecaoTitulo({required this.titulo, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, color: const Color(0xFF064E2F)),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
