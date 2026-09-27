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
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
    ),

    // Fundo padrão do app
    scaffoldBackgroundColor: backgroundColor,

    // Estilo padrão dos campos de entrada
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      prefixIconColor: primaryGreen,
      suffixIconColor: primaryGreen,
    ),

    // 1. Padronização global para botões normais/elevados (ElevatedButton)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primaryGreen.withOpacity(0.38),
        disabledForegroundColor: Colors.white70,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // 2. Padronização global para botões com contorno (OutlinedButton)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: primaryGreen,
        disabledForegroundColor: primaryGreen.withOpacity(0.38),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: const BorderSide(color: primaryGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // 3. Padronização global para botões preenchidos do Material 3 (FilledButton)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primaryGreen.withOpacity(0.38),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // 4. Padronização global para botões de texto simples (TextButton)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    // 5. Padronização global para botões de ícone (IconButton)
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: primaryGreen,
      ),
    ),

    // 6. Padronização do botão flutuante (FloatingActionButton)
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
  );
}