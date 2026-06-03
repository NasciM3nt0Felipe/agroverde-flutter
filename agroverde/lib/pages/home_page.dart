import 'package:agroverde/routes.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f8f5),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.eco, color: Color(0xff064e2f), size: 32),
                const SizedBox(width: 8),
                const Text(
                  'AgroVerde',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  child: const Text('Entrar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.cadastro);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff064e2f),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Criar conta'),
                ),
              ],
            ),

            const SizedBox(height: 110),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xffece6d4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('🌱 Gestão completa do agronegócio'),
            ),

            const SizedBox(height: 28),

            const Text(
              'Sua fazenda, no controle',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            const Text(
              'Gerencie talhões, estoque de insumos, rebanho e finanças em um só sistema.\n'
              'Decisões melhores, safras mais rentáveis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff064e2f),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 20,
                ),
              ),
              child: const Text('Começar agora  →'),
            ),

            const SizedBox(height: 90),

            Row(
              children: const [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.grass,
                    title: 'Talhões e Safras',
                    description: 'Controle de áreas, plantios e colheitas',
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.inventory_2_outlined,
                    title: 'Estoque',
                    description: 'Sementes, fertilizantes e defensivos',
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.pets,
                    title: 'Rebanho',
                    description: 'Animais, pesagens e manejo',
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Financeiro',
                    description: 'Receitas, despesas e fluxo de caixa',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xfff7f8f5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xffdddddd)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Color(0xff064e2f)),
            SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}
