import 'package:flutter/material.dart';

import '../data/sqlite/propriedade_repository.dart';
import '../domain/entities/propriedade.dart';
import '../domain/services/sessao_service.dart';
import '../routes.dart';

class PropriedadePage extends StatefulWidget {
  const PropriedadePage({super.key});

  @override
  State<PropriedadePage> createState() => _PropriedadePageState();
}

class _PropriedadePageState extends State<PropriedadePage> {
  final _formKey = GlobalKey<FormState>();

  final PropriedadeRepository _propriedadeRepository = PropriedadeRepository();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _areaTotalController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  List<Propriedade> _propriedades = [];

  bool _mostrarFormulario = false;
  bool _editando = false;
  int? _propriedadeEditandoId;

  @override
  void initState() {
    super.initState();
    _carregarPropriedades();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _areaTotalController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarPropriedades() async {
    final lista = await _propriedadeRepository.listarPorUsuarioId(
      SessaoService.usuarioId,
    );

    if (lista.length == 1 && SessaoService.propriedadeId == null) {
      SessaoService.definirPropriedade(lista.first);
    }

    setState(() {
      _propriedades = lista;
    });
  }

  Future<void> _salvarPropriedade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final propriedade = Propriedade(
      id: _propriedadeEditandoId,
      usuarioId: SessaoService.usuarioId,
      nome: _nomeController.text.trim(),
      areaTotal: double.parse(_areaTotalController.text.replaceAll(',', '.')),
      cidade: _cidadeController.text.trim(),
      estado: _estadoController.text.trim(),
      descricao: _descricaoController.text.trim(),
    );

    if (_editando) {
      await _propriedadeRepository.atualizar(propriedade);
    } else {
      await _propriedadeRepository.inserir(propriedade);
    }

    await _carregarPropriedades();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editando
              ? 'Propriedade atualizada com sucesso!'
              : 'Propriedade cadastrada com sucesso!',
        ),
      ),
    );

    _cancelarFormulario();
  }

  Future<void> _excluirPropriedade(Propriedade propriedade) async {
    await _propriedadeRepository.excluir(propriedade.id!);

    if (SessaoService.propriedadeId == propriedade.id) {
      SessaoService.limparPropriedade();
    }

    await _carregarPropriedades();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Propriedade excluída com sucesso!')),
    );
  }

  void _selecionarPropriedade(Propriedade propriedade) {
    SessaoService.definirPropriedade(propriedade);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Propriedade ativa: ${propriedade.nome}')),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => false,
    );
  }

  void _abrirFormularioCadastro() {
    _limparCampos();

    setState(() {
      _mostrarFormulario = true;
      _editando = false;
      _propriedadeEditandoId = null;
    });
  }

  void _editarPropriedade(Propriedade propriedade) {
    _nomeController.text = propriedade.nome;
    _areaTotalController.text = propriedade.areaTotal.toString();
    _cidadeController.text = propriedade.cidade ?? '';
    _estadoController.text = propriedade.estado ?? '';
    _descricaoController.text = propriedade.descricao ?? '';

    setState(() {
      _mostrarFormulario = true;
      _editando = true;
      _propriedadeEditandoId = propriedade.id;
    });
  }

  void _cancelarFormulario() {
    _limparCampos();

    setState(() {
      _mostrarFormulario = false;
      _editando = false;
      _propriedadeEditandoId = null;
    });
  }

  void _limparCampos() {
    _nomeController.clear();
    _areaTotalController.clear();
    _cidadeController.clear();
    _estadoController.clear();
    _descricaoController.clear();
  }

  bool _estaSelecionada(Propriedade propriedade) {
    return SessaoService.propriedadeId == propriedade.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propriedades'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_mostrarFormulario)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _abrirFormularioCadastro,
                      icon: const Icon(Icons.add),
                      label: const Text('Nova Propriedade'),
                    ),
                  ),

                if (_mostrarFormulario) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(
                              _editando
                                  ? 'Editar Propriedade'
                                  : 'Cadastro de Propriedade',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome da propriedade',
                                prefixIcon: Icon(Icons.home_work),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome da propriedade';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _areaTotalController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Área total (hectares)',
                                prefixIcon: Icon(Icons.square_foot),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe a área total';
                                }

                                final area = double.tryParse(
                                  value.replaceAll(',', '.'),
                                );

                                if (area == null || area <= 0) {
                                  return 'Informe uma área válida';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _cidadeController,
                              decoration: const InputDecoration(
                                labelText: 'Cidade',
                                prefixIcon: Icon(Icons.location_city),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _estadoController,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                                prefixIcon: Icon(Icons.flag),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _descricaoController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Descrição',
                                prefixIcon: Icon(Icons.description),
                              ),
                            ),

                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _salvarPropriedade,
                                child: Text(
                                  _editando
                                      ? 'Salvar Alterações'
                                      : 'Salvar Propriedade',
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _cancelarFormulario,
                                child: const Text('Cancelar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Minhas Propriedades',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (_propriedades.isEmpty)
                          const Text('Nenhuma propriedade cadastrada.')
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _propriedades.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final propriedade = _propriedades[index];
                              final selecionada = _estaSelecionada(propriedade);

                              return ListTile(
                                leading: Icon(
                                  selecionada
                                      ? Icons.agriculture
                                      : Icons.home_work,
                                  color: selecionada
                                      ? Colors.green
                                      : const Color(0xFF064E2F),
                                ),
                                title: Text(propriedade.nome),
                                subtitle: Text(
                                  '${propriedade.cidade ?? ''} - ${propriedade.estado ?? ''}',
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _selecionarPropriedade(propriedade);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: selecionada
                                            ? Colors.green
                                            : const Color(0xff8B6F47),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        selecionada ? 'Ativa' : 'Em Espera',
                                      ),
                                    ),

                                    OutlinedButton(
                                      onPressed: () {
                                        _editarPropriedade(propriedade);
                                      },
                                      child: const Text('Editar'),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        _excluirPropriedade(propriedade);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Excluir'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
