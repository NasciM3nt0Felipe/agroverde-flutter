import 'package:flutter/material.dart';

import '../data/sqlite/financeiro_repository.dart';
import '../domain/entities/lancamento_financeiro.dart';
import '../domain/services/sessao_service.dart';

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

  // Estado da comunicação com a API.
  bool _carregando = false;
  bool _salvando = false;
  String? _erroCarregamento;

  static const Color _verde = Color(0xFF064E2F);

  // Apenas lançamentos pagos compõem receitas, despesas e saldo:
  // pendentes e cancelados não alteram o saldo disponível.
  double get totalReceitas {
    return _lancamentos
        .where((l) => l.pago && l.tipo == 'receita')
        .fold(0, (total, l) => total + l.valor);
  }

  double get totalDespesas {
    return _lancamentos
        .where((l) => l.pago && l.tipo == 'despesa')
        .fold(0, (total, l) => total + l.valor);
  }

  double get saldo => totalReceitas - totalDespesas;

  // Valores pendentes, exibidos apenas como informação.
  double get receitasPendentes {
    return _lancamentos
        .where((l) => l.pendente && l.tipo == 'receita')
        .fold(0, (total, l) => total + l.valor);
  }

  double get despesasPendentes {
    return _lancamentos
        .where((l) => l.pendente && l.tipo == 'despesa')
        .fold(0, (total, l) => total + l.valor);
  }

  bool get _financeiroIndisponivel => _erroCarregamento != null;

  @override
  void initState() {
    super.initState();
    _carregarLancamentos();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  /// Carrega os lançamentos financeiros da propriedade em foco.
  ///
  /// Em caso de falha, não exibe totais zerados como se fossem válidos:
  /// a tela passa a mostrar o estado de indisponibilidade.
  Future<void> _carregarLancamentos() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      setState(() {
        _lancamentos = [];
        _erroCarregamento = null;
      });
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      final dados = await _repository.listarPorPropriedadeId(propriedadeId);

      if (!mounted) return;

      setState(() {
        _lancamentos = dados;
        _erroCarregamento = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _lancamentos = [];
        _erroCarregamento = _mensagemErro(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  /// Salva ou atualiza um lançamento financeiro.
  Future<void> _salvarLancamento() async {
    // Evita lançamentos duplicados por clique repetido.
    if (_salvando) return;

    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      _mostrarMensagem('Selecione uma propriedade em foco primeiro.');
      return;
    }

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
      propriedadeId: propriedadeId,
      descricao: descricao,
      valor: valor,
      tipo: _tipoSelecionado,
      data: DateTime.now().toIso8601String(),
      safraId: null,
    );

    setState(() {
      _salvando = true;
    });

    try {
      if (_idEditando == null) {
        await _repository.inserir(lancamento);
        _mostrarMensagem('Lançamento cadastrado com sucesso.');
      } else {
        await _repository.atualizar(lancamento);
        _mostrarMensagem('Lançamento atualizado com sucesso.');
      }
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(_mensagemErro(e));
      return;
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }

    if (!mounted) return;

    _limparCampos();
    await _carregarLancamentos();
  }

  /// Preenche o formulário para edição do lançamento.
  void _editarLancamento(LancamentoFinanceiro lancamento) {
    if (!lancamento.permiteEditar) {
      _mostrarMensagem(
        'Lançamentos automáticos são alterados no módulo de origem.',
      );
      return;
    }

    setState(() {
      _idEditando = lancamento.id;
      _descricaoController.text = lancamento.descricao;
      _valorController.text = lancamento.valor.toStringAsFixed(2);
      _tipoSelecionado = lancamento.tipo;
    });
  }

  /// Remove um lançamento financeiro e atualiza a listagem.
  Future<void> _excluirLancamento(LancamentoFinanceiro lancamento) async {
    if (_salvando || lancamento.id == null) return;

    if (!lancamento.permiteExcluir) {
      _mostrarMensagem(
        'Este lançamento pertence ao módulo de origem e não pode ser excluído.',
      );
      return;
    }

    // Lançamento automático: avisa que o registro de origem não muda.
    if (lancamento.automatico) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Excluir lançamento automático'),
            content: Text(
              'Este lançamento foi gerado por '
              '"${OrigemLancamento.rotulo(lancamento.origemTipo!)}".\n\n'
              'Apenas o lançamento financeiro será excluído; o registro no '
              'módulo de origem não será alterado. Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Excluir'),
              ),
            ],
          );
        },
      );

      if (confirmado != true || !mounted) return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await _repository.excluir(lancamento.id!);
    } catch (e) {
      if (!mounted) return;

      _mostrarMensagem(_mensagemErro(e));
      return;
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }

    if (!mounted) return;

    if (_idEditando == lancamento.id) {
      _limparCampos();
    }

    await _carregarLancamentos();

    if (!mounted) return;

    _mostrarMensagem('Lançamento excluído.');
  }

  /// Limpa os campos do formulário.
  void _limparCampos() {
    setState(() {
      _idEditando = null;
      _descricaoController.clear();
      _valorController.clear();
      _tipoSelecionado = 'receita';
    });
  }

  /// Extrai a mensagem de erro (ApiException ou validação) para exibição.
  String _mensagemErro(Object erro) {
    return erro.toString().replaceAll('Exception: ', '');
  }

  /// Exibe mensagens informativas ao usuário.
  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  /// Formata valores monetários para exibição.
  String _formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Formata aaaa-MM-dd como dd/MM/aaaa.
  String _formatarData(String data) {
    if (data.length < 10) return data;

    final partes = data.substring(0, 10).split('-');

    if (partes.length != 3) return data;

    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  /// Valor exibido nos indicadores (indisponível quando a API falhou).
  String _valorIndicador(double valor) {
    return _financeiroIndisponivel ? 'Indisponível' : _formatarValor(valor);
  }

  /// Cor dos indicadores (cinza quando a API está indisponível),
  /// no mesmo padrão do Dashboard.
  Color _corIndicador(Color cor) {
    return _financeiroIndisponivel ? Colors.grey : cor;
  }

  /// Cor e rótulo do status do lançamento.
  Color _corStatus(LancamentoFinanceiro item) {
    if (item.cancelado) return Colors.grey;
    if (item.pendente) return Colors.orange.shade800;
    return Colors.green.shade700;
  }

  String _rotuloStatus(LancamentoFinanceiro item) {
    if (item.cancelado) return 'Cancelado';
    if (item.pendente) return 'Pendente';
    return 'Pago';
  }

  @override
  Widget build(BuildContext context) {
    final nomePropriedade = SessaoService.propriedadeNome;
    final semPropriedade = SessaoService.propriedadeId == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        backgroundColor: _verde,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar lançamentos',
            onPressed: _carregando || semPropriedade
                ? null
                : _carregarLancamentos,
            icon: _carregando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
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
                const SizedBox(height: 8),
                Text(
                  nomePropriedade == null
                      ? 'Selecione uma propriedade para gerenciar os lançamentos.'
                      : 'Propriedade: $nomePropriedade',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                if (_financeiroIndisponivel) ...[
                  _AvisoIndisponivel(
                    mensagem: _erroCarregamento!,
                    aoTentarNovamente: _carregando ? null : _carregarLancamentos,
                  ),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _IndicadorCard(
                      titulo: 'Receitas',
                      valor: _valorIndicador(totalReceitas),
                      icone: Icons.trending_up,
                      corIcone: _corIndicador(Colors.green),
                      corValor: _corIndicador(Colors.green),
                    ),
                    _IndicadorCard(
                      titulo: 'Despesas',
                      valor: _valorIndicador(totalDespesas),
                      icone: Icons.trending_down,
                      corIcone: _corIndicador(Colors.red),
                      corValor: _corIndicador(Colors.red),
                    ),
                    _IndicadorCard(
                      titulo: 'Saldo',
                      valor: _valorIndicador(saldo),
                      icone: _financeiroIndisponivel
                          ? Icons.cloud_off
                          : Icons.account_balance_wallet,
                      corIcone: _corIndicador(saldo < 0 ? Colors.red : _verde),
                      corValor: _corIndicador(saldo < 0 ? Colors.red : _verde),
                    ),
                  ],
                ),
                if (!_financeiroIndisponivel && !semPropriedade) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Os totais consideram apenas lançamentos pagos.'
                    '${receitasPendentes > 0 || despesasPendentes > 0 ? ' Pendentes: receitas ${_formatarValor(receitasPendentes)} · despesas ${_formatarValor(despesasPendentes)}.' : ''}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
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
                          enabled: !semPropriedade,
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _valorController,
                          enabled: !semPropriedade,
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
                          onChanged: semPropriedade
                              ? null
                              : (value) {
                                  setState(() {
                                    _tipoSelecionado = value!;
                                  });
                                },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 45),
                              ),
                              onPressed: semPropriedade || _salvando
                                  ? null
                                  : _salvarLancamento,
                              icon: _salvando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      _idEditando == null
                                          ? Icons.save
                                          : Icons.edit,
                                    ),
                              label: Text(
                                _idEditando == null ? 'Cadastrar' : 'Atualizar',
                              ),
                            ),
                            if (_idEditando != null) ...[
                              const SizedBox(width: 12),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 45),
                                ),
                                onPressed: _salvando ? null : _limparCampos,
                                child: const Text('Cancelar edição'),
                              ),
                            ],
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
                _financeiroIndisponivel
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Gráfico indisponível no momento.'),
                          ),
                        ),
                      )
                    : _GraficoFinanceiro(
                        receitas: totalReceitas,
                        despesas: totalDespesas,
                      ),
                const SizedBox(height: 24),
                const Text(
                  'Lançamentos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _construirLista(semPropriedade),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lista de lançamentos com status, origem e ações permitidas.
  Widget _construirLista(bool semPropriedade) {
    if (semPropriedade) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Selecione uma propriedade para visualizar os lançamentos.',
            ),
          ),
        ),
      );
    }

    if (_financeiroIndisponivel) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Não foi possível carregar os lançamentos. '
              'Use o botão de atualizar para tentar novamente.',
            ),
          ),
        ),
      );
    }

    if (_carregando && _lancamentos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_lancamentos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nenhum lançamento cadastrado.')),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lancamentos.length,
      itemBuilder: (context, index) {
        final item = _lancamentos[index];
        final receita = item.tipo == 'receita';
        final corStatus = _corStatus(item);

        final detalhes = <String>[
          receita ? 'Receita' : 'Despesa',
          if (item.data.isNotEmpty) _formatarData(item.data),
          if (item.automatico)
            'Automático: ${OrigemLancamento.rotulo(item.origemTipo!)}',
        ];

        return Card(
          // Pendentes e cancelados ficam visualmente atenuados.
          color: item.pago ? null : Colors.grey.shade100,
          child: ListTile(
            leading: Icon(
              receita ? Icons.arrow_upward : Icons.arrow_downward,
              color: item.pago
                  ? (receita ? Colors.green : Colors.red)
                  : Colors.grey,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    item.descricao,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _EtiquetaStatus(rotulo: _rotuloStatus(item), cor: corStatus),
                if (item.automatico) ...[
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: 'Lançamento gerado automaticamente',
                    child: Icon(Icons.bolt, size: 18, color: _verde),
                  ),
                ],
              ],
            ),
            subtitle: Text(detalhes.join(' · ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatarValor(item.valor),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.pago ? null : Colors.grey.shade700,
                    decoration: item.cancelado
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                // Só oferece as ações que a API permite.
                if (item.permiteEditar)
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit),
                    color: _verde,
                    onPressed: _salvando
                        ? null
                        : () {
                            _editarLancamento(item);
                          },
                  ),
                if (item.permiteExcluir)
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: _salvando
                        ? null
                        : () {
                            _excluirLancamento(item);
                          },
                  ),
                if (!item.permiteEditar && !item.permiteExcluir)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Tooltip(
                      message:
                          'Mantido pelo módulo de origem; não pode ser '
                          'alterado nem excluído aqui.',
                      child: Icon(Icons.lock_outline, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Etiqueta compacta com o status do lançamento.
class _EtiquetaStatus extends StatelessWidget {
  final String rotulo;
  final Color cor;

  const _EtiquetaStatus({required this.rotulo, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        border: Border.all(color: cor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        rotulo,
        style: TextStyle(
          fontSize: 12,
          color: cor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Aviso exibido quando o Financeiro não pôde ser carregado.
class _AvisoIndisponivel extends StatelessWidget {
  final String mensagem;
  final VoidCallback? aoTentarNovamente;

  const _AvisoIndisponivel({
    required this.mensagem,
    required this.aoTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Financeiro indisponível: $mensagem\n'
                'Os valores não foram exibidos para evitar informações incorretas.',
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: aoTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicadorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color? corIcone;
  final Color? corValor;

  const _IndicadorCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    this.corIcone,
    this.corValor,
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
              Icon(icone, size: 36, color: corIcone ?? const Color(0xFF064E2F)),
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: corValor,
                      ),
                    ),
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

class _GraficoFinanceiro extends StatelessWidget {
  final double receitas;
  final double despesas;

  const _GraficoFinanceiro({required this.receitas, required this.despesas});

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
    final valorFormatado =
        'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

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