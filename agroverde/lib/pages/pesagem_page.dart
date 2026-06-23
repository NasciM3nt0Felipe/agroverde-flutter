import 'package:flutter/material.dart';

import '../data/sqlite/pesagem_repository.dart';
import '../data/sqlite/rebanho_repository.dart';
import '../domain/entities/animal.dart';
import '../domain/entities/pesagem_rebanho.dart';

class PesagemPage extends StatefulWidget {
  final Animal? animal;

  const PesagemPage({super.key, this.animal});

  @override
  State<PesagemPage> createState() => _PesagemPageState();
}

class _PesagemPageState extends State<PesagemPage> {
  final PesagemRepository _pesagemRepository = PesagemRepository();
  final RebanhoRepository _rebanhoRepository = RebanhoRepository();

  final _pesoController = TextEditingController();
  final _dataController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Animal> _animais = [];
  List<PesagemRebanho> _pesagens = [];

  int? _animalSelecionadoId;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final animais = await _rebanhoRepository.listar();
    final pesagens = await _pesagemRepository.listar();

    setState(() {
      _animais = animais;
      _pesagens = pesagens;

      if (widget.animal != null) {
        _animalSelecionadoId = widget.animal!.id;
      }
    });
  }

  Future<void> _salvarPesagem() async {
    if (_animalSelecionadoId == null) {
      _mostrarMensagem('Selecione um animal.');
      return;
    }

    final pesoTexto = _pesoController.text.trim().replaceAll(',', '.');
    final data = _dataController.text.trim();

    if (pesoTexto.isEmpty || data.isEmpty) {
      _mostrarMensagem('Preencha peso e data.');
      return;
    }

    final peso = double.tryParse(pesoTexto);

    if (peso == null || peso <= 0) {
      _mostrarMensagem('Informe um peso válido.');
      return;
    }

    final pesagem = PesagemRebanho(
      animalId: _animalSelecionadoId!,
      peso: peso,
      data: data,
      observacao: _observacaoController.text.trim(),
    );

    await _pesagemRepository.inserir(pesagem);

    _pesoController.clear();
    _dataController.clear();
    _observacaoController.clear();

    setState(() {
      _animalSelecionadoId = null;
    });

    await _carregarDados();

    _mostrarMensagem('Pesagem registrada com sucesso.');
  }

  Future<void> _excluirPesagem(int id) async {
    await _pesagemRepository.excluir(id);
    await _carregarDados();
    _mostrarMensagem('Pesagem excluída.');
  }

  String _nomeAnimal(int animalId) {
    final animal = _animais.where((a) => a.id == animalId).toList();

    if (animal.isEmpty) {
      return 'Animal não encontrado';
    }

    return '${animal.first.identificacao} - ${animal.first.especie}';
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<PesagemRebanho> get _pesagensFiltradas {
    if (_animalSelecionadoId == null) {
      return _pesagens;
    }

    return _pesagens
        .where((pesagem) => pesagem.animalId == _animalSelecionadoId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Pesagem'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registro de Pesagens',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nova pesagem',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

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
                                  value: animal.id!,
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

                        TextField(
                          controller: _pesoController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Peso em kg',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _dataController,
                          decoration: const InputDecoration(
                            labelText: 'Data da pesagem',
                            hintText: 'Ex: 13/06/2026',
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
                          onPressed: _salvarPesagem,
                          icon: const Icon(Icons.save),
                          label: const Text('Registrar pesagem'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Histórico de Pesagens',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _pesagensFiltradas.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Nenhuma pesagem registrada.'),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pesagensFiltradas.length,
                        itemBuilder: (context, index) {
                          final pesagem = _pesagensFiltradas[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.monitor_weight,
                                color: Color(0xFF064E2F),
                              ),
                              title: Text(_nomeAnimal(pesagem.animalId)),
                              subtitle: Text(
                                'Peso: ${pesagem.peso} kg | Data: ${pesagem.data}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _excluirPesagem(pesagem.id!);
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
