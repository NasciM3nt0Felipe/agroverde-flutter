import 'package:flutter/material.dart';
import 'package:agroverde/routes.dart';
import 'package:agroverde/domain/services/sessao_service.dart';

import '../data/sqlite/talhao_repository.dart';
import '../data/sqlite/safra_repository.dart';
import '../data/sqlite/rebanho_repository.dart';
import '../data/sqlite/financeiro_repository.dart';
import '../data/sqlite/estoque_repository.dart';
import '../data/sqlite/veiculo_repository.dart';
import '../domain/entities/estoque_item.dart';
import '../domain/entities/lancamento_financeiro.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TalhaoRepository _talhaoRepository = TalhaoRepository();
  final SafraRepository _safraRepository = SafraRepository();
  final RebanhoRepository _rebanhoRepository = RebanhoRepository();
  final FinanceiroRepository _financeiroRepository = FinanceiroRepository();
  final VeiculoRepository _veiculoRepository = VeiculoRepository();
  final EstoqueRepository _estoqueRepository = EstoqueRepository();

  // Veículos (API): status "Ativo" e "Manutenção" da tela de Veículos.
  int _veiculosAtivos = 0;
  int _veiculosManutencao = 0;
  bool _veiculosIndisponiveis = false;

  // Alertas de estoque (API): itens zerados primeiro, depois os baixos.
  List<EstoqueItem> _alertasEstoque = [];
  bool _estoqueIndisponivel = false;

  int _totalTalhoes = 0;
  int _totalSafras = 0;
  int _totalAnimais = 0;

  double _receitas = 0;
  double _despesas = 0;
  double _saldo = 0;

  // Preenchido quando o Financeiro (API) não pôde ser carregado.
  // Nesse caso os cards financeiros mostram "Indisponível", nunca R$ 0,00.
  String? _erroFinanceiro;

  // Verdadeiro quando talhões/safras (API) não puderam ser carregados.
  bool _talhoesIndisponiveis = false;

  bool _carregando = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDashboard();
    });
  }

  /// Navega para uma página e atualiza os indicadores ao retornar.
  Future<void> _abrirRota(String rota) async {
    await Navigator.pushNamed(context, rota);

    if (!mounted) return;

    await _carregarDashboard();
  }

  /// Carrega os indicadores principais da propriedade em foco.
  Future<void> _carregarDashboard() async {
    final propriedadeId = SessaoService.propriedadeId;

    setState(() {
      _carregando = true;
    });

    if (propriedadeId == null) {
      setState(() {
        _totalTalhoes = 0;
        _totalSafras = 0;
        _totalAnimais = 0;
        _receitas = 0;
        _despesas = 0;
        _saldo = 0;
        _erroFinanceiro = null;
        _talhoesIndisponiveis = false;
        _veiculosAtivos = 0;
        _veiculosManutencao = 0;
        _veiculosIndisponiveis = false;
        _alertasEstoque = [];
        _estoqueIndisponivel = false;
        _carregando = false;
      });
      return;
    }

    int totalTalhoes = 0;
    int totalSafras = 0;
    bool talhoesIndisponiveis = false;

    // Talhões e safras vêm da API: uma falha não deve travar o Dashboard.
    try {
      final talhoes = await _talhaoRepository.listarPorPropriedadeId(
        propriedadeId,
      );

      totalTalhoes = talhoes.length;

      for (final talhao in talhoes) {
        final safras = await _safraRepository.listarPorTalhaoId(talhao.id!);

        final safrasEmExecucao = safras.where((safra) {
          final status = safra.status.toLowerCase();

          return status == 'planejada' || status == 'em andamento';
        }).length;

        totalSafras += safrasEmExecucao;
      }
    } catch (_) {
      talhoesIndisponiveis = true;
    }

    // O rebanho vem da API: uma falha não deve travar o Dashboard.
    int totalAnimais = 0;

    try {
      totalAnimais = (await _rebanhoRepository.listarPorPropriedadeId(
        propriedadeId,
      )).length;
    } catch (_) {
      totalAnimais = 0;
    }

    // Veículos e estoque vêm da API: uma falha não deve travar o Dashboard.
    int veiculosAtivos = 0;
    int veiculosManutencao = 0;
    bool veiculosIndisponiveis = false;

    try {
      final veiculos = await _veiculoRepository.listarPorPropriedadeId(
        propriedadeId,
      );

      veiculosAtivos = veiculos.where((v) => v.status == 'Ativo').length;
      veiculosManutencao = veiculos
          .where((v) => v.status == 'Manutenção')
          .length;
    } catch (_) {
      veiculosIndisponiveis = true;
    }

    var alertasEstoque = <EstoqueItem>[];
    bool estoqueIndisponivel = false;

    try {
      final itens = await _estoqueRepository.listarPorPropriedadeId(
        propriedadeId,
      );

      // Mesmas regras de status da tela de Estoque.
      alertasEstoque =
          itens.where((i) => i.estoqueZerado || i.estoqueBaixo).toList()
            ..sort((a, b) {
              if (a.estoqueZerado != b.estoqueZerado) {
                return a.estoqueZerado ? -1 : 1;
              }

              return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
            });
    } catch (_) {
      estoqueIndisponivel = true;
    }

    double receitas = 0;
    double despesas = 0;

    // O Financeiro vem da API: uma falha não deve travar o Dashboard
    // nem ser exibida como saldo zerado.
    var lancamentos = <LancamentoFinanceiro>[];
    String? erroFinanceiro;

    try {
      lancamentos = await _financeiroRepository.listarPorPropriedadeId(
        propriedadeId,
      );
    } catch (e) {
      erroFinanceiro = e.toString().replaceAll('Exception: ', '');
    }

    for (final lancamento in lancamentos) {
      // Pendentes e cancelados não compõem receitas, despesas nem saldo.
      if (!lancamento.pago) continue;

      if (lancamento.tipo.toLowerCase() == 'receita') {
        receitas += lancamento.valor;
      } else {
        despesas += lancamento.valor;
      }
    }

    if (!mounted) return;

    setState(() {
      _totalTalhoes = totalTalhoes;
      _totalSafras = totalSafras;
      _talhoesIndisponiveis = talhoesIndisponiveis;
      _totalAnimais = totalAnimais;
      _veiculosAtivos = veiculosAtivos;
      _veiculosManutencao = veiculosManutencao;
      _veiculosIndisponiveis = veiculosIndisponiveis;
      _alertasEstoque = alertasEstoque;
      _estoqueIndisponivel = estoqueIndisponivel;
      _receitas = receitas;
      _despesas = despesas;
      _saldo = receitas - despesas;
      _erroFinanceiro = erroFinanceiro;
      _carregando = false;
    });
  }

  /// Formata valores monetários para exibição.
  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  bool get _financeiroIndisponivel => _erroFinanceiro != null;

  /// Valor dos cards financeiros: "Indisponível" quando a API falhou.
  String _valorFinanceiro(double valor) {
    return _financeiroIndisponivel ? 'Indisponível' : _formatarMoeda(valor);
  }

  /// Cor dos cards financeiros (cinza quando indisponível).
  Color _corFinanceira(Color cor) {
    return _financeiroIndisponivel ? Colors.grey : cor;
  }

  @override
  Widget build(BuildContext context) {
    final nomePropriedade = SessaoService.propriedadeSelecionada?.nome;

    return Scaffold(
      drawer: _AppDrawer(abrirRota: _abrirRota),
      appBar: AppBar(
        title: const Text('AgroVerde'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Atualizar painel',
            onPressed: _carregarDashboard,
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Backg-teste.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.88),
          child: Center(
            child: ConstrainedBox(
              // Largura de 3 cards por linha: o conteúdo fica centralizado
              // e os cards alinhados entre as seções.
              constraints: const BoxConstraints(maxWidth: 740),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌾 ${nomePropriedade ?? "Nenhuma propriedade selecionada"}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Painel de gestão da propriedade.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E2F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            nomePropriedade == null
                                ? Icons.eco
                                : Icons.home_work,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              nomePropriedade == null
                                  ? 'Ficaremos felizes em acompanhar seu desenvolvimento.'
                                  : 'Você está gerenciando: $nomePropriedade',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _TituloSecao(
                      titulo: 'Financeiro',
                      icone: Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _DashboardCard(
                          titulo: 'Despesas',
                          valor: _valorFinanceiro(_despesas),
                          icone: Icons.trending_down,
                          corIcone: _corFinanceira(Colors.red),
                          corValor: _corFinanceira(Colors.red),
                        ),
                        _DashboardCard(
                          titulo: 'Receitas',
                          valor: _valorFinanceiro(_receitas),
                          icone: Icons.trending_up,
                          corIcone: _corFinanceira(Colors.green),
                          corValor: _corFinanceira(Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DashboardCard(
                      titulo: 'Saldo',
                      valor: _valorFinanceiro(_saldo),
                      icone: _financeiroIndisponivel
                          ? Icons.cloud_off
                          : Icons.account_balance_wallet,
                      corIcone: _corFinanceira(
                        _saldo < 0 ? Colors.red : const Color(0xFF064E2F),
                      ),
                      corValor: _corFinanceira(
                        _saldo < 0 ? Colors.red : const Color(0xFF064E2F),
                      ),
                      largura: 456,
                    ),
                    if (_financeiroIndisponivel) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.cloud_off,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Financeiro indisponível: $_erroFinanceiro\n'
                                  'Saldo, receitas e despesas não foram '
                                  'exibidos para evitar valores incorretos.',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _carregando
                                    ? null
                                    : _carregarDashboard,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    const _TituloSecao(
                      titulo: 'Operacional',
                      icone: Icons.agriculture,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _DashboardCard(
                          titulo: 'Talhões',
                          valor: _talhoesIndisponiveis
                              ? 'Indisponível'
                              : _totalTalhoes.toString(),
                          icone: Icons.agriculture,
                        ),
                        _DashboardCard(
                          titulo: 'Safras',
                          valor: _talhoesIndisponiveis
                              ? 'Indisponível'
                              : _totalSafras.toString(),
                          icone: Icons.grass,
                        ),
                        _DashboardCard(
                          titulo: 'Animais',
                          valor: _totalAnimais.toString(),
                          icone: Icons.pets,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _AlertasEstoqueCard(
                          alertas: _alertasEstoque,
                          indisponivel: _estoqueIndisponivel,
                        ),
                        _DashboardCard(
                          titulo: 'Veículos ativos',
                          valor: _veiculosIndisponiveis
                              ? 'Indisponível'
                              : _veiculosAtivos.toString(),
                          icone: Icons.local_shipping,
                        ),
                        _DashboardCard(
                          titulo: 'Em manutenção',
                          valor: _veiculosIndisponiveis
                              ? 'Indisponível'
                              : _veiculosManutencao.toString(),
                          icone: Icons.build,
                          corIcone: _veiculosManutencao > 0
                              ? Colors.orange.shade800
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 32),
                    const Text(
                      'Acesso rápido',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _QuickAccessCard(
                          titulo: 'Funcionários',
                          subtitulo: 'Equipe e responsáveis',
                          rota: AppRoutes.funcionarios,
                          abrirRota: _abrirRota,
                        ),
                        _QuickAccessCard(
                          titulo: 'Veículos',
                          subtitulo: 'Máquinas e equipamentos',
                          rota: AppRoutes.veiculos,
                          abrirRota: _abrirRota,
                        ),
                        _QuickAccessCard(
                          titulo: 'Talhões e Safras',
                          subtitulo: 'Gerencie áreas e culturas',
                          rota: AppRoutes.talhoesSafras,
                          abrirRota: _abrirRota,
                        ),
                        _QuickAccessCard(
                          titulo: 'Colheita',
                          subtitulo: 'Produção agrícola',
                          rota: AppRoutes.colheita,
                          abrirRota: _abrirRota,
                        ),
                        _QuickAccessCard(
                          titulo: 'Estoque',
                          subtitulo: 'Controle de insumos',
                          rota: AppRoutes.estoque,
                          abrirRota: _abrirRota,
                        ),
                        _QuickAccessCard(
                          titulo: 'Rebanho',
                          subtitulo: 'Gestão animal',
                          rota: AppRoutes.rebanho,
                          abrirRota: _abrirRota,
                        ),
                        _QuickAccessCard(
                          titulo: 'Financeiro',
                          subtitulo: 'Receitas e despesas',
                          rota: AppRoutes.financeiro,
                          abrirRota: _abrirRota,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color? corIcone;
  final Color? corValor;
  final double largura;

  const _DashboardCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    this.corIcone,
    this.corValor,
    this.largura = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: largura,
      height: 150,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(icone, color: corIcone ?? const Color(0xFF064E2F), size: 32),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: corValor ?? Colors.black,
                ),
              ),
              Text(titulo),
            ],
          ),
        ),
      ),
    );
  }
}

/// Box compacta com os itens de estoque zerados (vermelho) e baixos
/// (amarelo), com rolagem interna.
/// Título discreto de seção do painel.
class _TituloSecao extends StatelessWidget {
  final String titulo;
  final IconData icone;

  const _TituloSecao({required this.titulo, required this.icone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 20, color: const Color(0xFF064E2F)),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF064E2F),
          ),
        ),
      ],
    );
  }
}

class _AlertasEstoqueCard extends StatelessWidget {
  final List<EstoqueItem> alertas;
  final bool indisponivel;

  const _AlertasEstoqueCard({
    required this.alertas,
    required this.indisponivel,
  });

  @override
  Widget build(BuildContext context) {
    Widget conteudo;

    if (indisponivel) {
      conteudo = const Center(
        child: Text('Indisponível', style: TextStyle(color: Colors.grey)),
      );
    } else if (alertas.isEmpty) {
      conteudo = const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Color(0xFF064E2F), size: 18),
            SizedBox(width: 6),
            Text(
              'Estoque em dia',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      conteudo = Scrollbar(
        thumbVisibility: alertas.length > 3,
        child: ListView.builder(
          padding: const EdgeInsets.only(right: 8),
          itemCount: alertas.length,
          itemBuilder: (context, index) {
            final item = alertas[index];
            final zerado = item.estoqueZerado;
            final cor = zerado ? Colors.red.shade700 : Colors.amber.shade800;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 9, color: cor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.nome,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    zerado ? 'Zerado' : 'Baixo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      width: 220,
      height: 150,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2,
                    size: 20,
                    color: Color(0xFF064E2F),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Alertas de Estoque',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(child: conteudo),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String rota;
  final Future<void> Function(String rota) abrirRota;

  const _QuickAccessCard({
    required this.titulo,
    required this.subtitulo,
    required this.rota,
    required this.abrirRota,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.eco, color: Color(0xFF064E2F)),
          title: Text(titulo),
          subtitle: Text(subtitulo),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            abrirRota(rota);
          },
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final Future<void> Function(String rota) abrirRota;

  const _AppDrawer({required this.abrirRota});

  void _navegar(BuildContext context, String rota) {
    Navigator.pop(context);
    abrirRota(rota);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF064E2F)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 45,
                    child: Stack(
                      alignment: Alignment.center,
                      children: const [
                        Positioned(
                          left: 10,
                          top: 4,
                          child: Icon(Icons.eco, size: 42, color: Colors.black),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 4,
                          child: Icon(Icons.eco, size: 42, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AgroVerde',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Gestão Rural',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Perfil'),
                  onTap: () => _navegar(context, AppRoutes.perfil),
                ),
                ListTile(
                  leading: const Icon(Icons.home_work),
                  title: const Text('Propriedades'),
                  onTap: () => _navegar(context, AppRoutes.propriedades),
                ),
                ListTile(
                  leading: const Icon(Icons.groups),
                  title: const Text('Funcionários'),
                  onTap: () => _navegar(context, AppRoutes.funcionarios),
                ),
                ListTile(
                  leading: const Icon(Icons.agriculture),
                  title: const Text('Veículos'),
                  onTap: () => _navegar(context, AppRoutes.veiculos),
                ),
                ListTile(
                  leading: const Icon(Icons.eco),
                  title: const Text('Talhões e Safras'),
                  onTap: () => _navegar(context, AppRoutes.talhoesSafras),
                ),
                ListTile(
                  leading: const Icon(Icons.grass),
                  title: const Text('Colheita'),
                  onTap: () => _navegar(context, AppRoutes.colheita),
                ),
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Estoque'),
                  onTap: () => _navegar(context, AppRoutes.estoque),
                ),
                ListTile(
                  leading: const Icon(Icons.pets),
                  title: const Text('Rebanho'),
                  onTap: () => _navegar(context, AppRoutes.rebanho),
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Financeiro'),
                  onTap: () => _navegar(context, AppRoutes.financeiro),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
          ),
        ],
      ),
    );
  }
}