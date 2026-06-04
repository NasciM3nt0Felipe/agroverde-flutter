import 'package:flutter/material.dart';

/// Classe responsável pelo tema global da aplicação.
/// Centraliza cores, estilos e configurações visuais
/// para evitar repetições nas telas.
class AppTheme {
  // Cores oficiais do projeto AgroVerde
  static const Color primaryGreen = Color(0xFF064E2F);
  static const Color backgroundColor = Color(0xFFF7F8F5);
  static const Color accentColor = Color(0xFFECE6D4);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // Cor principal do AgroVerde
    colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),

    // Fundo padrão do app
    scaffoldBackgroundColor: backgroundColor,

    // Estilo padrão dos campos de entrada
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      prefixIconColor: primaryGreen,
      suffixIconColor: primaryGreen,
    ),
  );
}
