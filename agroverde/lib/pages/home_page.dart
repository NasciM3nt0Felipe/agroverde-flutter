import 'dart:async';

import 'package:agroverde/routes.dart';
import 'package:flutter/material.dart';
import 'package:agroverde/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _startIndex = 0;

  final List<_CarouselItem> _carouselItems = const [
    _CarouselItem(
      imagePath: 'assets/images/home_talhoes.jpg',
      title: 'Talhões e Safras',
      description: 'Acompanhe áreas, plantios e colheitas com precisão.',
    ),
    _CarouselItem(
      imagePath: 'assets/images/home_rebanho.jpg',
      title: 'Rebanho saudável',
      description: 'Controle pesagens, manejo e indicadores do gado.',
    ),
    _CarouselItem(
      imagePath: 'assets/images/home_estoque.jpg',
      title: 'Estoque organizado',
      description: 'Sementes, fertilizantes e defensivos sempre sob controle.',
    ),
    _CarouselItem(
      imagePath: 'assets/images/home_trabalho.jpg',
      title: 'Tudo na palma das mãos',
      description:
          'Acesse informações importantes da fazenda de forma simples.',
    ),
  ];
  // O carrossel funciona exibindo apenas parte da lista.
  //logica
  late final Timer _carouselTimer;

  @override
  void initState() {
    super.initState();

    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _startIndex = (_startIndex + 1) % _carouselItems.length;
      });
    });
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    super.dispose();
  }

  List<_CarouselItem> get _visibleCarouselItems {
    return List.generate(3, (index) {
      final itemIndex = (_startIndex + index) % _carouselItems.length;
      return _carouselItems[itemIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(-10, 0),
                            child: const Icon(
                              Icons.eco,
                              size: 36,
                              color: Colors.black,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(7, 0),
                            child: Icon(
                              Icons.eco,
                              size: 36,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Agro',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: 'Verde',
                              style: TextStyle(color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 20,
                            vertical: isMobile ? 10 : 14,
                          ),
                          textStyle: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Entrar'),
                      ),

                      const SizedBox(width: 8),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.cadastro);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff8B6F47),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 20,
                            vertical: isMobile ? 10 : 14,
                          ),
                          textStyle: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Text(isMobile ? 'Criar' : 'Criar Conta'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 110),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 220, 191, 136),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.agriculture,
                          size: 30,
                          color: AppTheme.primaryGreen,
                        ),
                        SizedBox(width: 6),
                        Text('Gestão completa do agronegócio'),
                      ],
                    ),
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

                  const SizedBox(height: 48),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isMobile = constraints.maxWidth < 700;

                      final List<_CarouselItem> visibleItems = isMobile
                          ? [_visibleCarouselItems.first]
                          : _visibleCarouselItems;

                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: visibleItems.map((item) {
                          return SizedBox(
                            width: isMobile ? constraints.maxWidth : 360,
                            child: _CarouselCard(
                              imagePath: item.imagePath,
                              title: item.title,
                              description: item.description,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 150),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: const [
                          SizedBox(
                            width: 260,
                            child: _FeatureCard(
                              icon: Icons.grass,
                              title: 'Talhões e Safras',
                              description:
                                  'Controle de áreas, plantios e colheitas',
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: _FeatureCard(
                              icon: Icons.inventory_2_outlined,
                              title: 'Estoque',
                              description:
                                  'Sementes, fertilizantes e defensivos',
                            ),
                          ),
                          SizedBox(
                            height: 190, //para ele ficar na mesma altura
                            width: 260,
                            child: _FeatureCard(
                              icon: Icons.pets,
                              title: 'Rebanho',
                              description: 'Animais, pesagens e manejo',
                            ),
                          ),
                          SizedBox(
                            width: 260,
                            child: _FeatureCard(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Financeiro',
                              description:
                                  'Receitas, despesas e fluxo de caixa',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CarouselItem {
  final String imagePath;
  final String title;
  final String description;

  const _CarouselItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
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
      color: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xffdddddd)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 34, color: AppTheme.primaryGreen),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const _CarouselCard({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: Container(
        key: ValueKey(imagePath),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.72), Colors.transparent],
            ),
          ),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 6,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 6,
                      color: Colors.black87,
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
