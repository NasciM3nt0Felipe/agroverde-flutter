import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/cadastro_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/pessoa_page.dart';
import 'pages/propriedade_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String cadastro = '/cadastro';
  static const String dashboard = '/dashboard';
  static const String perfil = '/perfil';
  static const String propriedades = '/propriedades';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    login: (context) => const LoginPage(),
    cadastro: (context) => const CadastroPage(),
    dashboard: (context) => const DashboardPage(),
    perfil: (context) => const PessoaPage(),
    propriedades: (context) => const PropriedadePage(),
  };
}
