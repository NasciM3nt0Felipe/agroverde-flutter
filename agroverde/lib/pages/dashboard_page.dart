import 'package:flutter/material.dart';
import 'package:agroverde/routes.dart';
import 'package:agroverde/domain/services/sessao_service.dart';

import '../data/sqlite/talhao_repository.dart';
import '../data/sqlite/safra_repository.dart';
import '../data/sqlite/rebanho_repository.dart';
import '../data/sqlite/financeiro_repository.dart';

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

  int _totalTalhoes = 0;
  int _totalSafras = 0;
  int _totalAnimais = 0;

  double _receitas = 0;
  double _despesas = 0;
  double _saldo = 0;

  bool _carregando = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDashboard();
    });
  }

  Future<void> _abrirRota(String rota) async {
    await Navigator.pushNamed(context, rota);

    if (!mounted) return;

    await _carregarDashboard();
  }

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
        _carregando = false;
      });
      return;
    }

    final talhoes = await _talhaoRepository.listarPorPropriedadeId(
      propriedadeId,
    );

    int totalSafras = 0;

    for (final talhao in talhoes) {
      final safras = await _safraRepository.listarPorTalhaoId(talhao.id!);

      final safrasEmExecucao = safras.where((safra) {
        final status = safra.status.toLowerCase();

        return status == 'planejada' || status == 'em andamento';
      }).length;

      totalSafras += safrasEmExecucao;
    }

    final animais = await _rebanhoRepository.listarPorPropriedadeId(
      propriedadeId,
    );

    final lancamentos = await _financeiroRepository.listarPorPropriedadeId(
      propriedadeId,
    );

    double receitas = 0;
    double despesas = 0;

    for (final lancamento in lancamentos) {
      if (lancamento.tipo.toLowerCase() == 'receita') {
        receitas += lancamento.valor;
      } else {
        despesas += lancamento.valor;
      }
    }

    if (!mounted) return;

    setState(() {
      _totalTalhoes = talhoes.length;
      _totalSafras = totalSafras;
      _totalAnimais = animais.length;
      _receitas = receitas;
      _despesas = despesas;
      _saldo = receitas - despesas;
      _carregando = false;
    });
  }

  String _formatarMoeda(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
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
              constraints: const BoxConstraints(maxWidth: 1200),
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

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _DashboardCard(
                          titulo: 'Talhões',
                          valor: _totalTalhoes.toString(),
                          icone: Icons.agriculture,
                        ),
                        _DashboardCard(
                          titulo: 'Safras',
                          valor: _totalSafras.toString(),
                          icone: Icons.grass,
                        ),
                        _DashboardCard(
                          titulo: 'Animais',
                          valor: _totalAnimais.toString(),
                          icone: Icons.pets,
                        ),
                        _DashboardCard(
                          titulo: 'Saldo',
                          valor: _formatarMoeda(_saldo),
                          icone: Icons.account_balance_wallet,
                          corIcone: _saldo < 0
                              ? Colors.red
                              : const Color(0xFF064E2F),
                          corValor: _saldo < 0
                              ? Colors.red
                              : const Color(0xFF064E2F),
                        ),
                        _DashboardCard(
                          titulo: 'Receitas',
                          valor: _formatarMoeda(_receitas),
                          icone: Icons.trending_up,
                          corIcone: Colors.green,
                          corValor: Colors.green,
                        ),
                        _DashboardCard(
                          titulo: 'Despesas',
                          valor: _formatarMoeda(_despesas),
                          icone: Icons.trending_down,
                          corIcone: Colors.red,
                          corValor: Colors.red,
                        ),
                      ],
                    ),

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

  const _DashboardCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    this.corIcone,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
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
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
              },
              icon: const Icon(
                Icons.logout,
                color: Color.fromARGB(255, 55, 50, 49),
              ),
              label: const Text(
                'Sair',
                style: TextStyle(color: Color.fromARGB(255, 52, 48, 47)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
