import 'package:flutter/material.dart';

/// Classe responsável pelo tema global da aplicação.
/// Centraliza cores, estilos e configurações visuais
/// para evitar repetições nas telas.
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    // Cor principal do AgroVerde (VERDE)
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),

    // Estilo padrão dos campos de entrada
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
