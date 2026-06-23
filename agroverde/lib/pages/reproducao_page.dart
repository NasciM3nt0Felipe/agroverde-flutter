import 'package:flutter/material.dart';

import '../data/sqlite/rebanho_repository.dart';
import '../data/sqlite/reproducao_repository.dart';
import '../domain/entities/animal.dart';
import '../domain/entities/reproducao_rebanho.dart';

class ReproducaoPage extends StatefulWidget {
  final Animal? animal;

  const ReproducaoPage({super.key, this.animal});

  @override
  State<ReproducaoPage> createState() => _ReproducaoPageState();
}

class _ReproducaoPageState extends State<ReproducaoPage> {
  final ReproducaoRepository _repository = ReproducaoRepository();
  final RebanhoRepository _rebanhoRepository = RebanhoRepository();

  final _dataController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Animal> _animais = [];
  List<ReproducaoRebanho> _registros = [];

  int? _animalSelecionadoId;

  String _tipoSelecionado = 'Cobertura';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final animais = await _rebanhoRepository.listar();
    final registros = await _repository.listar();

    setState(() {
      _animais = animais;
      _registros = registros;

      if (widget.animal != null) {
        _animalSelecionadoId = widget.animal!.id;
      }
    });
  }

  Future<void> _salvar() async {
    if (_animalSelecionadoId == null) {
      _mostrarMensagem('Selecione um animal.');
      return;
    }

    if (_dataController.text.trim().isEmpty) {
      _mostrarMensagem('Informe a data.');
      return;
    }

    final registro = ReproducaoRebanho(
      animalId: _animalSelecionadoId!,
      tipo: _tipoSelecionado,
      data: _dataController.text.trim(),
      observacao: _observacaoController.text.trim(),
    );

    await _repository.inserir(registro);

    _dataController.clear();
    _observacaoController.clear();
    if (widget.animal == null) {
      _animalSelecionadoId = null;
    }

    await _carregarDados();

    _mostrarMensagem('Registro salvo com sucesso.');
  }

  Future<void> _excluir(int id) async {
    await _repository.excluir(id);
    await _carregarDados();
  }

  String _nomeAnimal(int animalId) {
    final animal = _animais.where((a) => a.id == animalId).toList();

    if (animal.isEmpty) {
      return 'Animal não encontrado';
    }

    return '${animal.first.identificacao} - ${animal.first.especie}';
  }

  List<ReproducaoRebanho> get _registrosFiltrados {
    if (_animalSelecionadoId == null) {
      return _registros;
    }

    return _registros
        .where((registro) => registro.animalId == _animalSelecionadoId)
        .toList();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final coberturas = _registrosFiltrados
        .where((r) => r.tipo == 'Cobertura')
        .length;

    final inseminacoes = _registrosFiltrados
        .where((r) => r.tipo == 'Inseminação')
        .length;

    final prenhezes = _registrosFiltrados
        .where((r) => r.tipo == 'Prenhez')
        .length;

    final partos = _registrosFiltrados.where((r) => r.tipo == 'Parto').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Reprodução'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestão Reprodutiva',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _Indicador(
                      titulo: 'Coberturas',
                      valor: coberturas.toString(),
                      icone: Icons.favorite,
                    ),
                    _Indicador(
                      titulo: 'Inseminações',
                      valor: inseminacoes.toString(),
                      icone: Icons.science,
                    ),
                    _Indicador(
                      titulo: 'Prenhezes',
                      valor: prenhezes.toString(),
                      icone: Icons.pregnant_woman,
                    ),
                    _Indicador(
                      titulo: 'Partos',
                      valor: partos.toString(),
                      icone: Icons.child_care,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          value: _animalSelecionadoId,
                          decoration: const InputDecoration(
                            labelText: 'Animal',
                            border: OutlineInputBorder(),
                          ),
                          items: _animais
                              .where((animal) => animal.id != null)
                              .map((animal) {
                                return DropdownMenuItem<int>(
                                  value: animal.id,
                                  child: Text(
                                    '${animal.identificacao} - ${animal.especie}',
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (id) {
                            setState(() {
                              _animalSelecionadoId = id;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _tipoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Evento',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Cobertura',
                              child: Text('Cobertura'),
                            ),
                            DropdownMenuItem(
                              value: 'Inseminação',
                              child: Text('Inseminação'),
                            ),
                            DropdownMenuItem(
                              value: 'Prenhez',
                              child: Text('Prenhez'),
                            ),
                            DropdownMenuItem(
                              value: 'Parto',
                              child: Text('Parto'),
                            ),
                          ],
                          onChanged: (valor) {
                            setState(() {
                              _tipoSelecionado = valor!;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _dataController,
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _observacaoController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observação',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        ElevatedButton.icon(
                          onPressed: _salvar,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Histórico Reprodutivo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _registrosFiltrados.length,
                  itemBuilder: (context, index) {
                    final registro = _registrosFiltrados[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.favorite),
                        title: Text(_nomeAnimal(registro.animalId)),
                        subtitle: Text('${registro.tipo} - ${registro.data}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _excluir(registro.id!);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _Indicador({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 120,
      child: Card(
        child: Center(
          child: ListTile(
            leading: Icon(icone, color: const Color(0xFF064E2F)),
            title: Text(titulo),
            subtitle: Text(
              valor,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
