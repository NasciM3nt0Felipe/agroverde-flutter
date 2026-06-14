import 'package:flutter/material.dart';
import 'package:agroverde/routes.dart';
import 'package:agroverde/domain/services/sessao_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nomeUsuario = SessaoService.usuarioLogado?.nome ?? 'Usuário';
    final primeiroNome = nomeUsuario.split(' ').first;
    final nomePropriedade = SessaoService.propriedadeSelecionada?.nome;

    return Scaffold(
      drawer: const _AppDrawer(),
      appBar: AppBar(
        title: const Text('AgroVerde'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
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
                      'Olá, $primeiroNome! 👋',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

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
                            child: nomePropriedade == null
                                ? const Text(
                                    'Ficaremos felizes em acompanhar seu desenvolvimento.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Text(
                                    nomePropriedade,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
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
                      children: const [
                        _DashboardCard(
                          titulo: 'Talhões',
                          valor: '0',
                          icone: Icons.agriculture,
                        ),
                        _DashboardCard(
                          titulo: 'Safras',
                          valor: '0',
                          icone: Icons.grass,
                        ),
                        _DashboardCard(
                          titulo: 'Animais',
                          valor: '0',
                          icone: Icons.pets,
                        ),
                        _DashboardCard(
                          titulo: 'Saldo',
                          valor: 'R\$ 0,00',
                          icone: Icons.attach_money,
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
                      children: const [
                        _QuickAccessCard(
                          titulo: 'Talhões e Safras',
                          subtitulo: 'Gerencie áreas e culturas',
                        ),
                        _QuickAccessCard(
                          titulo: 'Estoque',
                          subtitulo: 'Controle de insumos',
                        ),
                        _QuickAccessCard(
                          titulo: 'Rebanho',
                          subtitulo: 'Gestão animal',
                        ),
                        _QuickAccessCard(
                          titulo: 'Financeiro',
                          subtitulo: 'Receitas e despesas',
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

  const _DashboardCard({
    required this.titulo,
    required this.valor,
    required this.icone,
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
              Icon(icone, color: const Color(0xFF064E2F), size: 32),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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

  const _QuickAccessCard({required this.titulo, required this.subtitulo});

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
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

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
                  leading: const Icon(Icons.home),
                  title: const Text('Início'),
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Perfil'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.perfil);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.home_work),
                  title: const Text('Propriedades'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.propriedades);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.agriculture),
                  title: const Text('Talhões e Safras'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.talhoesSafras);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Estoque'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.estoque);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.pets),
                  title: const Text('Rebanho'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.rebanho);
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Financeiro'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.financeiro);
                  },
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
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sair', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}
