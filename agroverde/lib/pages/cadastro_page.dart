import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../repositories/usuario_repository.dart';
import '../services/usuario_service.dart';
import '../routes.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final UsuarioService _usuarioService = UsuarioService();
  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  bool _obscurePassword = true;

  // Controla se o cadastro foi concluído com sucesso.
  bool _cadastroRealizado = false;

  // Armazena erro específico do campo e-mail vindo da regra de negócio.
  String? _erroEmail;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon),
      prefixIconColor: const Color(0xff0B5D35),
      suffixIcon: suffixIcon,
      errorText: errorText,
      border: const OutlineInputBorder(),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xff0B5D35), width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Future<void> _cadastrarUsuario() async {
    // Limpa erro anterior de e-mail.
    setState(() {
      _erroEmail = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usuarioExistente = await _usuarioRepository.buscarPorEmail(
      _emailController.text,
    );

    if (usuarioExistente != null) {
      setState(() {
        _erroEmail = 'Este e-mail já está cadastrado.';
      });
      return;
    }

    final usuario = Usuario(
      nome: _nomeController.text,
      email: _emailController.text,
      senha: _usuarioService.gerarHashSenha(_senhaController.text),
    );

    final id = await _usuarioRepository.inserir(usuario);

    final usuarios = await _usuarioRepository.listarTodos();

    debugPrint('Usuário salvo com ID: $id');
    debugPrint('Total de usuários cadastrados: ${usuarios.length}');

    for (final usuario in usuarios) {
      debugPrint(
        'ID: ${usuario.id} | Nome: ${usuario.nome} | Email: ${usuario.email}',
      );
    }

    if (!mounted) return;

    // Após salvar com sucesso, muda o estado da tela.
    setState(() {
      _cadastroRealizado = true;

      // Limpa os campos após o cadastro ser concluído.
      _nomeController.clear();
      _emailController.clear();
      _senhaController.clear();
      _confirmarSenhaController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/background-agro.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black38,
                  color: const Color(0xffF7FBF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                  size: 42,
                                  color: Colors.black,
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(8, 0),
                                child: const Icon(
                                  Icons.eco,
                                  size: 42,
                                  color: Color(0xff0B5D35),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Agro',
                                  style: TextStyle(color: Colors.black),
                                ),
                                TextSpan(
                                  text: 'Verde',
                                  style: TextStyle(color: Color(0xff0B5D35)),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Exibe "Crie sua conta" antes do cadastro
                          // e "Cadastrado" após salvar no banco.
                          if (!_cadastroRealizado)
                            const Text(
                              'Crie sua conta',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                            )
                          else
                            Container(
                              width: 240,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xff0B5D35),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Cadastrado',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 26),

                          TextFormField(
                            enabled: !_cadastroRealizado,
                            controller: _nomeController,
                            decoration: _inputDecoration(
                              labelText: 'Nome Completo',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (_cadastroRealizado) return null;
                              if (value == null || value.isEmpty) {
                                return 'Informe seu nome completo';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            enabled: !_cadastroRealizado,
                            controller: _emailController,
                            onChanged: (_) {
                              if (_erroEmail != null) {
                                setState(() {
                                  _erroEmail = null;
                                });
                              }
                            },
                            decoration: _inputDecoration(
                              labelText: 'E-mail',
                              icon: Icons.email_outlined,
                              errorText: _erroEmail,
                            ),
                            validator: (value) {
                              if (_cadastroRealizado) return null;
                              if (value == null || value.isEmpty) {
                                return 'Informe seu e-mail';
                              }

                              final emailValido = RegExp(
                                r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
                              ).hasMatch(value);

                              if (!emailValido) {
                                return 'Informe um e-mail válido';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            enabled: !_cadastroRealizado,
                            controller: _senhaController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              labelText: 'Senha',
                              icon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xff0B5D35),
                                ),
                                onPressed: _cadastroRealizado
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                              ),
                            ),
                            validator: (value) {
                              if (_cadastroRealizado) return null;
                              if (value == null || value.isEmpty) {
                                return 'Informe sua senha';
                              }

                              if (value.length < 8) {
                                return 'A senha deve ter no mínimo 8 caracteres';
                              }

                              if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) {
                                return 'A senha deve conter um caractere especial';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            enabled: !_cadastroRealizado,
                            controller: _confirmarSenhaController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              labelText: 'Confirmar Senha',
                              icon: Icons.lock_outline,
                            ),
                            validator: (value) {
                              if (_cadastroRealizado) return null;
                              if (value == null || value.isEmpty) {
                                return 'Confirme sua senha';
                              }

                              if (value != _senhaController.text) {
                                return 'As senhas não conferem';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 26),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff0B5D35),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: () async {
                                // Se já cadastrou, o botão passa a levar para o Login.
                                if (_cadastroRealizado) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  );
                                  return;
                                }

                                await _cadastrarUsuario();
                              },
                              child: Text(
                                _cadastroRealizado
                                    ? 'Ir para Login'
                                    : 'Criar Conta',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
