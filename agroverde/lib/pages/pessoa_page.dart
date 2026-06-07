import 'package:flutter/material.dart';

import '../data/sqlite/pessoa_repository.dart';
import '../domain/entities/pessoa.dart';
import '../domain/services/pessoa_service.dart';
import '../domain/services/sessao_service.dart';

class PessoaPage extends StatefulWidget {
  const PessoaPage({super.key});

  @override
  State<PessoaPage> createState() => _PessoaPageState();
}

class _PessoaPageState extends State<PessoaPage> {
  final _formKey = GlobalKey<FormState>();

  Pessoa? _pessoaAtual;

  // Controla se os campos podem ser editados.
  bool _modoEdicao = true;

  final PessoaRepository _pessoaRepository = PessoaRepository();
  final PessoaService _pessoaService = PessoaService();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerfil() async {
    final pessoa = await _pessoaRepository.buscarPorUsuarioId(
      SessaoService.usuarioId,
    );

    if (pessoa == null) {
      return;
    }

    _pessoaAtual = pessoa;

    _nomeController.text = pessoa.nome ?? '';
    _cpfController.text = pessoa.cpf ?? '';
    _telefoneController.text = pessoa.telefone ?? '';
    _cepController.text = pessoa.cep ?? '';
    _ruaController.text = pessoa.rua ?? '';
    _numeroController.text = pessoa.numero ?? '';
    _bairroController.text = pessoa.bairro ?? '';
    _cidadeController.text = pessoa.cidade ?? '';
    _estadoController.text = pessoa.estado ?? '';

    setState(() {
      // Se já existe perfil, começa em modo visualização.
      _modoEdicao = false;
    });
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bool perfilJaExistia = _pessoaAtual != null;

    final pessoa = Pessoa(
      id: _pessoaAtual?.id,
      usuarioId: SessaoService.usuarioId,
      nome: _nomeController.text,
      cpf: _cpfController.text,
      telefone: _telefoneController.text,
      cep: _cepController.text,
      rua: _ruaController.text,
      numero: _numeroController.text,
      bairro: _bairroController.text,
      cidade: _cidadeController.text,
      estado: _estadoController.text,
    );

    if (perfilJaExistia) {
      await _pessoaRepository.atualizar(pessoa);
    } else {
      await _pessoaRepository.inserir(pessoa);
    }

    _pessoaAtual = await _pessoaRepository.buscarPorUsuarioId(
      SessaoService.usuarioId,
    );

    if (!mounted) return;

    setState(() {
      // Após salvar, volta para modo visualização.
      _modoEdicao = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          perfilJaExistia
              ? 'Perfil atualizado com sucesso!'
              : 'Perfil salvo com sucesso!',
        ),
      ),
    );
  }

  void _habilitarEdicao() {
    setState(() {
      _modoEdicao = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do Usuário')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 700,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Dados Pessoais',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe seu nome';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _cpfController,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe seu CPF';
                          }

                          if (!_pessoaService.cpfValido(value)) {
                            return 'CPF deve conter 11 dígitos';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Endereço',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _cepController,
                        decoration: const InputDecoration(
                          labelText: 'CEP',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _ruaController,
                        decoration: const InputDecoration(
                          labelText: 'Rua',
                          prefixIcon: Icon(Icons.home),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _numeroController,
                        decoration: const InputDecoration(
                          labelText: 'Número',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _bairroController,
                        decoration: const InputDecoration(
                          labelText: 'Bairro',
                          prefixIcon: Icon(Icons.map),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _cidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        enabled: _modoEdicao,
                        controller: _estadoController,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: Icon(Icons.flag),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _modoEdicao
                              ? _salvarPerfil
                              : _habilitarEdicao,
                          child: Text(
                            _modoEdicao
                                ? (_pessoaAtual == null
                                      ? 'Salvar Perfil'
                                      : 'Salvar Alterações')
                                : 'Editar Perfil',
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
    );
  }
}
