import 'package:flutter/material.dart';
import 'package:agroverde/routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Olá, Felipe! 👋',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aqui está o resumo da sua propriedade.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF064E2F)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'AgroVerde',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Gestão Rural', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          const ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
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
          const ListTile(leading: Icon(Icons.pets), title: Text('Rebanho')),

          const ListTile(
            leading: Icon(Icons.attach_money),
            title: Text('Financeiro'),
          ),
        ],
      ),
    );
  }
}
