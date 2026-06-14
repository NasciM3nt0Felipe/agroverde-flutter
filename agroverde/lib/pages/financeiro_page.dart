import 'package:flutter/material.dart';

import '../data/sqlite/financeiro_repository.dart';
import '../domain/entities/lancamento_financeiro.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  final FinanceiroRepository _repository = FinanceiroRepository();

  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();

  List<LancamentoFinanceiro> _lancamentos = [];
  String _tipoSelecionado = 'receita';
  int? _idEditando;

  double get totalReceitas {
    return _lancamentos
        .where((l) => l.tipo == 'receita')
        .fold(0, (total, l) => total + l.valor);
  }

  double get totalDespesas {
    return _lancamentos
        .where((l) => l.tipo == 'despesa')
        .fold(0, (total, l) => total + l.valor);
  }

  double get saldo => totalReceitas - totalDespesas;

  @override
  void initState() {
    super.initState();
    _carregarLancamentos();
  }

  Future<void> _carregarLancamentos() async {
    final dados = await _repository.listar();
    setState(() {
      _lancamentos = dados;
    });
  }

  Future<void> _salvarLancamento() async {
    final descricao = _descricaoController.text.trim();
    final valorTexto = _valorController.text.trim().replaceAll(',', '.');

    if (descricao.isEmpty || valorTexto.isEmpty) {
      _mostrarMensagem('Preencha a descrição e o valor.');
      return;
    }

    final valor = double.tryParse(valorTexto);

    if (valor == null || valor <= 0) {
      _mostrarMensagem('Informe um valor válido.');
      return;
    }

    final lancamento = LancamentoFinanceiro(
      id: _idEditando,
      descricao: descricao,
      valor: valor,
      tipo: _tipoSelecionado,
      data: DateTime.now().toIso8601String(),
      safraId: null,
    );

    if (_idEditando == null) {
      await _repository.inserir(lancamento);
      _mostrarMensagem('Lançamento cadastrado com sucesso.');
    } else {
      await _repository.atualizar(lancamento);
      _mostrarMensagem('Lançamento atualizado com sucesso.');
    }

    _limparCampos();
    await _carregarLancamentos();
  }

  void _editarLancamento(LancamentoFinanceiro lancamento) {
    setState(() {
      _idEditando = lancamento.id;
      _descricaoController.text = lancamento.descricao;
      _valorController.text = lancamento.valor.toStringAsFixed(2);
      _tipoSelecionado = lancamento.tipo;
    });
  }

  Future<void> _excluirLancamento(int id) async {
    await _repository.excluir(id);
    await _carregarLancamentos();
    _mostrarMensagem('Lançamento excluído.');
  }

  void _limparCampos() {
    setState(() {
      _idEditando = null;
      _descricaoController.clear();
      _valorController.clear();
      _tipoSelecionado = 'receita';
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestão Financeira',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _IndicadorCard(
                      titulo: 'Receitas',
                      valor: _formatarValor(totalReceitas),
                      icone: Icons.trending_up,
                    ),
                    _IndicadorCard(
                      titulo: 'Despesas',
                      valor: _formatarValor(totalDespesas),
                      icone: Icons.trending_down,
                    ),
                    _IndicadorCard(
                      titulo: 'Saldo',
                      valor: _formatarValor(saldo),
                      icone: Icons.account_balance_wallet,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _idEditando == null
                              ? 'Novo lançamento'
                              : 'Editar lançamento',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _descricaoController,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _valorController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Valor',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _tipoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'receita',
                              child: Text('Receita'),
                            ),
                            DropdownMenuItem(
                              value: 'despesa',
                              child: Text('Despesa'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _tipoSelecionado = value!;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _salvarLancamento,
                              icon: Icon(
                                _idEditando == null
                                    ? Icons.save
                                    : Icons.edit,
                              ),
                              label: Text(
                                _idEditando == null
                                    ? 'Cadastrar'
                                    : 'Atualizar',
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_idEditando != null)
                              OutlinedButton(
                                onPressed: _limparCampos,
                                child: const Text('Cancelar edição'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Gráfico de Receitas e Despesas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _GraficoFinanceiro(
                  receitas: totalReceitas,
                  despesas: totalDespesas,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Lançamentos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _lancamentos.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Nenhum lançamento cadastrado.'),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _lancamentos.length,
                        itemBuilder: (context, index) {
                          final item = _lancamentos[index];

                          return Card(
                            child: ListTile(
                              leading: Icon(
                                item.tipo == 'receita'
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: item.tipo == 'receita'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(item.descricao),
                              subtitle: Text(
                                item.tipo == 'receita'
                                    ? 'Receita'
                                    : 'Despesa',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatarValor(item.valor),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _editarLancamento(item);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _excluirLancamento(item.id!);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicadorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _IndicadorCard({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 130,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icone, size: 36, color: const Color(0xFF064E2F)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo),
                    const SizedBox(height: 8),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _GraficoFinanceiro extends StatelessWidget {
  final double receitas;
  final double despesas;

  const _GraficoFinanceiro({
    required this.receitas,
    required this.despesas,
  });

  @override
  Widget build(BuildContext context) {
    final maiorValor = receitas > despesas ? receitas : despesas;
    final receitaPercentual = maiorValor == 0 ? 0.0 : receitas / maiorValor;
    final despesaPercentual = maiorValor == 0 ? 0.0 : despesas / maiorValor;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _BarraGrafico(
              titulo: 'Receitas',
              valor: receitas,
              percentual: receitaPercentual,
              cor: Colors.green,
            ),
            const SizedBox(height: 16),
            _BarraGrafico(
              titulo: 'Despesas',
              valor: despesas,
              percentual: despesaPercentual,
              cor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraGrafico extends StatelessWidget {
  final String titulo;
  final double valor;
  final double percentual;
  final Color cor;

  const _BarraGrafico({
    required this.titulo,
    required this.valor,
    required this.percentual,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final valorFormatado = 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$titulo - $valorFormatado'),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentual,
          minHeight: 16,
          backgroundColor: Colors.grey.shade300,
          color: cor,
        ),
      ],
    );
  }
}