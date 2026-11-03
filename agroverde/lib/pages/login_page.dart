import 'package:flutter/material.dart';
import 'package:agroverde/routes.dart';

// Repositório responsável por solicitar o login à API.
import '../data/sqlite/usuario_repository.dart';
import '../data/sqlite/propriedade_repository.dart';

// Classe que representa os erros retornados pela API.
import '../data/api/api_exception.dart';

// Serviço responsável por guardar o usuário autenticado.
import '../domain/services/sessao_service.dart';

/// Tela de autenticação do AgroVerde.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controla se a senha fica visível ou oculta.
  bool _obscurePassword = true;

  // Controladores dos campos de e-mail e senha.
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _senhaController = TextEditingController();

  // Repositório utilizado para autenticar o usuário na API.
  final UsuarioRepository _usuarioRepository = UsuarioRepository();
  final PropriedadeRepository _propriedadeRepository = PropriedadeRepository();

  // Armazena a mensagem de erro exibida na tela.
  String? _erroLogin;

  // Indica se existe uma tentativa de login em andamento.
  bool _carregando = false;

  /// Libera os controladores quando a tela é destruída.
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  /// Realiza o login utilizando a API .NET 8.
  Future<void> _realizarLogin() async {
    // Impede duas tentativas simultâneas.
    if (_carregando) return;

    // Obtém os dados digitados pelo usuário.
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    // Limpa a mensagem de erro anterior.
    setState(() {
      _erroLogin = null;
    });

    // Validação básica dos campos.
    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _erroLogin = 'Informe e-mail e senha.';
      });
      return;
    }

    // Informa que a autenticação está em andamento.
    setState(() {
      _carregando = true;
    });

    try {
      // Envia as credenciais para a API .NET 8.
      //
      // O método autenticar():
      // 1. Faz POST /api/Auth/login.
      // 2. Recebe o token JWT e os dados do usuário.
      // 3. Armazena o token no ApiClient.
      // 4. Retorna um objeto Usuario.
      final usuario = await _usuarioRepository.autenticar(
        email: email,
        senha: senha,
      );

      // Verifica se a tela continua ativa.
      if (!mounted) return;

      // Inicia a sessão sem herdar a propriedade de outro login.
      SessaoService.limparPropriedade();
      SessaoService.definirUsuario(usuario);

      // A propriedade ativa precisa estar definida ANTES do Dashboard abrir.
      // A API retorna somente as propriedades pertencentes ao token JWT.
      final propriedades = await _propriedadeRepository.listarPorUsuarioId(
        SessaoService.usuarioId,
      );

      if (!mounted) return;

      // Regra: quando existe exatamente uma propriedade, ela fica ativa.
      // Com zero ou várias, não selecionamos nenhuma automaticamente.
      if (propriedades.length == 1) {
        SessaoService.definirPropriedade(propriedades.first);
      }

      // Redireciona para o dashboard.
      //
      // pushReplacementNamed substitui a tela atual,
      // evitando retornar ao login pelo botão Voltar.
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } on ApiException catch (e) {
      // Captura erros conhecidos da API:
      // credenciais inválidas, falha de conexão etc.
      if (!mounted) return;

      setState(() {
        _erroLogin = e.message;
      });
    } catch (e) {
      // Captura erros inesperados para evitar que
      // o aplicativo seja encerrado.
      if (!mounted) return;

      debugPrint('Erro inesperado no login: $e');

      setState(() {
        _erroLogin = 'Não foi possível realizar o login.';
      });
    } finally {
      // Finaliza o estado de carregamento,
      // desde que a tela continue ativa.
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Imagem de fundo original do AgroVerde.
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background-agro.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),

        // Centraliza a janela de autenticação.
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
                      // Logotipo original com duas folhas.
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

                      // Nome AgroVerde com cores diferentes.
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

                      // Campo de e-mail.
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Campo de senha.
                      TextField(
                        controller: _senhaController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),

                          // Botão para mostrar ou ocultar a senha.
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

                      // Exibe mensagens de erro, quando houver.
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

                      // Botão Entrar.
                      //
                      // Durante a autenticação, fica desabilitado
                      // e apresenta um indicador de carregamento.
                      ElevatedButton(
                        onPressed: _carregando ? null : _realizarLogin,
                        child: _carregando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
                      ),

                      const SizedBox(height: 16),

                      // Separador visual.
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

                      // Botão Google original.
                      //
                      // A autenticação Google ainda não
                      // está implementada neste projeto.
                      OutlinedButton(
                        onPressed: () {
                          debugPrint('Login com Google');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/icons/google.png', height: 24),
                            const SizedBox(width: 10),
                            const Text('Entrar com Google'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Navegação para o cadastro.
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.cadastro);
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Crie sua conta'),
                      ),

                      const SizedBox(height: 8),

                      // Recuperação de senha ainda não implementada.
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
