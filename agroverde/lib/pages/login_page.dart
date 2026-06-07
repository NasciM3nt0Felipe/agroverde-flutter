import '../repositories/usuario_repository.dart';
import '../services/usuario_service.dart';

import 'package:flutter/material.dart';
import 'package:agroverde/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true; // Variável para mostrar/ocultar senha

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  final UsuarioRepository _usuarioRepository = UsuarioRepository();
  final UsuarioService _usuarioService = UsuarioService();

  String? _erroLogin;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _realizarLogin() async {
    setState(() {
      _erroLogin = null;
    });

    final email = _emailController.text;
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _erroLogin = 'Informe e-mail e senha.';
      });
      return;
    }

    final usuario = await _usuarioRepository.buscarPorEmail(email);

    if (usuario == null) {
      setState(() {
        _erroLogin = 'E-mail ou senha inválidos.';
      });
      return;
    }

    final senhaHash = _usuarioService.gerarHashSenha(senha);

    if (senhaHash != usuario.senha) {
      setState(() {
        _erroLogin = 'E-mail ou senha inválidos.';
      });
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background-agro.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        // Janela de login
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(-10, 0),
                            child: const Icon(
                              Icons.eco,
                              size: 50,
                              color: Colors.black,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(10, 0),
                            child: const Icon(
                              Icons.eco,
                              size: 50,
                              color: Color(0xFF064E2F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: 'Agro',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: 'Verde',
                              style: TextStyle(color: Color(0xFF064E2F)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Acesse sua conta',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 24),

                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _senhaController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      if (_erroLogin != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _erroLogin!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF064E2F),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),

                          onPressed: _realizarLogin,
                          child: const Text(
                            'Entrar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('ou'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            print('Login com Google');
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/icons/google.png',
                                height: 28,
                              ),
                              const SizedBox(width: 10),
                              const Text('Entrar com Google'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.cadastro);
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Crie sua conta'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: () {},
                        child: const Text('Esqueci minha senha'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
