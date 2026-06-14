import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/cadastro_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/pessoa_page.dart';
import 'pages/propriedade_page.dart';
import 'pages/financeiro_page.dart';
import 'pages/rebanho_page.dart';
import 'pages/pesagem_page.dart';
import 'pages/vacinacao_page.dart';
import 'pages/sanitario_page.dart';
import 'pages/reproducao_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String cadastro = '/cadastro';
  static const String dashboard = '/dashboard';
  static const String perfil = '/perfil';
  static const String propriedades = '/propriedades';
  static const String financeiro = '/financeiro';
  static const String rebanho = '/rebanho';
  static const String pesagem = '/pesagem';
  static const String vacinacao = '/vacinacao';
  static const String sanitario = '/sanitario';
  static const String reproducao = '/reproducao';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    login: (context) => const LoginPage(),
    cadastro: (context) => const CadastroPage(),
    dashboard: (context) => const DashboardPage(),
    perfil: (context) => const PessoaPage(),
    propriedades: (context) => const PropriedadePage(),
    financeiro: (context) => const FinanceiroPage(),
    rebanho: (context) => const RebanhoPage(),
    pesagem: (context) => const PesagemPage(),
    vacinacao: (context) => const VacinacaoPage(),
    sanitario: (context) => const SanitarioPage(),
    reproducao: (context) => const ReproducaoPage(),
  };
}