import 'package:flutter/material.dart';
import '../data/sqlite/usuario_repository.dart';
import '../data/api/api_exception.dart';
import '../routes.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final UsuarioRepository _usuarioRepository = UsuarioRepository();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _cadastroRealizado = false;
  bool _cadastrando = false;

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
    if (_cadastrando || _cadastroRealizado) return;

    setState(() {
      _erroEmail = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cadastrando = true;
    });

    try {
      await _usuarioRepository.cadastrar(
        nome: _nomeController.text,
        email: _emailController.text,
        senha: _senhaController.text,
      );

      if (!mounted) return;

      setState(() {
        _cadastroRealizado = true;

        _nomeController.clear();
        _emailController.clear();
        _senhaController.clear();
        _confirmarSenhaController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
      );
    } on ApiException catch (erro) {
      if (!mounted) return;

      if (erro.statusCode == 409) {
        setState(() {
          _erroEmail = 'Este e-mail já está cadastrado.';
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(erro.message)));
      }
    } catch (erro) {
      if (!mounted) return;

      debugPrint('Erro ao cadastrar usuário: $erro');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível realizar o cadastro.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cadastrando = false;
        });
      }
    }
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
                            enabled: !_cadastroRealizado && !_cadastrando,
                            controller: _nomeController,
                            decoration: _inputDecoration(
                              labelText: 'Nome Completo',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (_cadastroRealizado) return null;

                              if (value == null || value.trim().isEmpty) {
                                return 'Informe seu nome completo';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: !_cadastroRealizado && !_cadastrando,
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

                              if (value == null || value.trim().isEmpty) {
                                return 'Informe seu e-mail';
                              }

                              final emailValido = RegExp(
                                r'^[\w\.-]+@[\w\.-]+\.\w{2,}$',
                              ).hasMatch(value.trim());

                              if (!emailValido) {
                                return 'Informe um e-mail válido';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: !_cadastroRealizado && !_cadastrando,
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
                                onPressed: _cadastroRealizado || _cadastrando
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
                            enabled: !_cadastroRealizado && !_cadastrando,
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
                          ElevatedButton(
                            onPressed: _cadastrando
                                ? null
                                : () async {
                                    if (_cadastroRealizado) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        AppRoutes.login,
                                      );
                                      return;
                                    }

                                    await _cadastrarUsuario();
                                  },
                            child: _cadastrando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _cadastroRealizado
                                        ? 'Ir para Login'
                                        : 'Criar Conta',
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
