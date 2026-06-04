import 'package:flutter/material.dart';
// Importa o tema global da aplicação, achei mais funcional.
import 'theme/app_theme.dart';
import 'routes.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, //Foi criado uma segmentação para o thema cor
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
