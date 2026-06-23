import 'package:flutter/material.dart';

import '../data/sqlite/rebanho_repository.dart';
import '../data/sqlite/sanitario_repository.dart';
import '../domain/entities/animal.dart';
import '../domain/entities/sanitario_rebanho.dart';

class SanitarioPage extends StatefulWidget {
  final Animal? animal;

  const SanitarioPage({super.key, this.animal});

  @override
  State<SanitarioPage> createState() => _SanitarioPageState();
}

class _SanitarioPageState extends State<SanitarioPage> {
  final SanitarioRepository _sanitarioRepository = SanitarioRepository();
  final RebanhoRepository _rebanhoRepository = RebanhoRepository();

  final _procedimentoController = TextEditingController();
  final _dataController = TextEditingController();
  final _medicamentoController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Animal> _animais = [];
  List<SanitarioRebanho> _registros = [];

  int? _animalSelecionadoId;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final animais = await _rebanhoRepository.listar();
    final registros = await _sanitarioRepository.listar();

    setState(() {
      _animais = animais;
      _registros = registros;

      if (widget.animal != null) {
        _animalSelecionadoId = widget.animal!.id;
      }
    });
  }

  Future<void> _salvarRegistro() async {
    if (_animalSelecionadoId == null) {
      _mostrarMensagem('Selecione um animal.');
      return;
    }

    final procedimento = _procedimentoController.text.trim();
    final data = _dataController.text.trim();

    if (procedimento.isEmpty || data.isEmpty) {
      _mostrarMensagem('Preencha procedimento e data.');
      return;
    }

    final registro = SanitarioRebanho(
      animalId: _animalSelecionadoId!,
      procedimento: procedimento,
      data: data,
      medicamento: _medicamentoController.text.trim(),
      observacao: _observacaoController.text.trim(),
    );

    await _sanitarioRepository.inserir(registro);

    _procedimentoController.clear();
    _dataController.clear();
    _medicamentoController.clear();
    _observacaoController.clear();

    setState(() {
      if (widget.animal == null) {
        _animalSelecionadoId = null;
      }
    });

    await _carregarDados();

    _mostrarMensagem('Registro sanitário salvo com sucesso.');
  }

  Future<void> _excluirRegistro(int id) async {
    await _sanitarioRepository.excluir(id);
    await _carregarDados();
    _mostrarMensagem('Registro sanitário excluído.');
  }

  String _nomeAnimal(int animalId) {
    final animal = _animais.where((a) => a.id == animalId).toList();

    if (animal.isEmpty) {
      return 'Animal não encontrado';
    }

    return '${animal.first.identificacao} - ${animal.first.especie}';
  }

  List<SanitarioRebanho> get _registrosFiltrados {
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
    final totalComMedicamento = _registrosFiltrados
        .where((r) => r.medicamento != null && r.medicamento!.isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Sanitário'),
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
                  'Controle Sanitário do Rebanho',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _IndicadorCard(
                      titulo: 'Registros',
                      valor: _registrosFiltrados.length.toString(),
                      icone: Icons.medical_services,
                    ),
                    _IndicadorCard(
                      titulo: 'Com medicamento',
                      valor: totalComMedicamento.toString(),
                      icone: Icons.healing,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Novo registro sanitário',
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
                          controller: _procedimentoController,
                          decoration: const InputDecoration(
                            labelText: 'Procedimento',
                            hintText: 'Ex: Vermifugação, tratamento, exame',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _dataController,
                          decoration: const InputDecoration(
                            labelText: 'Data',
                            hintText: 'Ex: 13/06/2026',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _medicamentoController,
                          decoration: const InputDecoration(
                            labelText: 'Medicamento',
                            hintText: 'Ex: Vermífugo, antibiótico',
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
                          onPressed: _salvarRegistro,
                          icon: const Icon(Icons.save),
                          label: const Text('Salvar registro'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Histórico Sanitário',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _registrosFiltrados.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Nenhum registro sanitário cadastrado.',
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _registrosFiltrados.length,
                        itemBuilder: (context, index) {
                          final registro = _registrosFiltrados[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.medical_services,
                                color: Color(0xFF064E2F),
                              ),
                              title: Text(_nomeAnimal(registro.animalId)),
                              subtitle: Text(
                                'Procedimento: ${registro.procedimento} | Data: ${registro.data} | Medicamento: ${registro.medicamento?.isEmpty ?? true ? '-' : registro.medicamento}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _excluirRegistro(registro.id!);
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

class _IndicadorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _IndicadorCard({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 120,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icone, size: 36, color: const Color(0xFF064E2F)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo),
                    const SizedBox(height: 8),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
