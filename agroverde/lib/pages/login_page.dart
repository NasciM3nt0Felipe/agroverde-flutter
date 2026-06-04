import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true; // Variável para mostrar/ocultar senha

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
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF064E2F),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),

                          onPressed: () {},
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
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.login),
                          label: const Text('Entrar com Google'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
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
