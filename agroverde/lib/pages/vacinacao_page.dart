import 'package:flutter/material.dart';

import '../data/sqlite/rebanho_repository.dart';
import '../data/sqlite/vacinacao_repository.dart';
import '../domain/entities/animal.dart';
import '../domain/entities/vacinacao_rebanho.dart';

class VacinacaoPage extends StatefulWidget {
  const VacinacaoPage({super.key});

  @override
  State<VacinacaoPage> createState() => _VacinacaoPageState();
}

class _VacinacaoPageState extends State<VacinacaoPage> {
  final VacinacaoRepository _vacinacaoRepository = VacinacaoRepository();
  final RebanhoRepository _rebanhoRepository = RebanhoRepository();

  final _vacinaController = TextEditingController();
  final _dataAplicacaoController = TextEditingController();
  final _proximaDoseController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Animal> _animais = [];
  List<VacinacaoRebanho> _vacinacoes = [];

  Animal? _animalSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final animais = await _rebanhoRepository.listar();
    final vacinacoes = await _vacinacaoRepository.listar();

    setState(() {
      _animais = animais;
      _vacinacoes = vacinacoes;
    });
  }

  Future<void> _salvarVacinacao() async {
    if (_animalSelecionado == null) {
      _mostrarMensagem('Selecione um animal.');
      return;
    }

    final vacina = _vacinaController.text.trim();
    final dataAplicacao = _dataAplicacaoController.text.trim();

    if (vacina.isEmpty || dataAplicacao.isEmpty) {
      _mostrarMensagem('Preencha a vacina e a data de aplicação.');
      return;
    }

    final vacinacao = VacinacaoRebanho(
      animalId: _animalSelecionado!.id!,
      vacina: vacina,
      dataAplicacao: dataAplicacao,
      proximaDose: _proximaDoseController.text.trim(),
      observacao: _observacaoController.text.trim(),
    );

    await _vacinacaoRepository.inserir(vacinacao);

    _vacinaController.clear();
    _dataAplicacaoController.clear();
    _proximaDoseController.clear();
    _observacaoController.clear();

    await _carregarDados();

    _mostrarMensagem('Vacinação registrada com sucesso.');
  }

  Future<void> _excluirVacinacao(int id) async {
    await _vacinacaoRepository.excluir(id);
    await _carregarDados();
    _mostrarMensagem('Registro de vacinação excluído.');
  }

  String _nomeAnimal(int animalId) {
    final animal = _animais.where((a) => a.id == animalId).toList();

    if (animal.isEmpty) {
      return 'Animal não encontrado';
    }

    return '${animal.first.identificacao} - ${animal.first.especie}';
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vacinasComProximaDose = _vacinacoes
        .where((v) => v.proximaDose != null && v.proximaDose!.isNotEmpty)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacinação do Rebanho'),
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
                  'Controle de Vacinação',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _IndicadorCard(
                      titulo: 'Registros',
                      valor: _vacinacoes.length.toString(),
                      icone: Icons.vaccines,
                    ),
                    _IndicadorCard(
                      titulo: 'Próximas doses',
                      valor: vacinasComProximaDose.toString(),
                      icone: Icons.event_available,
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
                          'Nova vacinação',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<Animal>(
                          value: _animalSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Animal',
                            border: OutlineInputBorder(),
                          ),
                          items: _animais.map((animal) {
                            return DropdownMenuItem<Animal>(
                              value: animal,
                              child: Text(
                                '${animal.identificacao} - ${animal.especie}',
                              ),
                            );
                          }).toList(),
                          onChanged: (animal) {
                            setState(() {
                              _animalSelecionado = animal;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _vacinaController,
                          decoration: const InputDecoration(
                            labelText: 'Vacina',
                            hintText: 'Ex: Febre aftosa',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _dataAplicacaoController,
                          decoration: const InputDecoration(
                            labelText: 'Data de aplicação',
                            hintText: 'Ex: 13/06/2026',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _proximaDoseController,
                          decoration: const InputDecoration(
                            labelText: 'Próxima dose',
                            hintText: 'Ex: 13/12/2026',
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
                          onPressed: _salvarVacinacao,
                          icon: const Icon(Icons.save),
                          label: const Text('Registrar vacinação'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Histórico de Vacinação',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                _vacinacoes.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Nenhuma vacinação registrada.'),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _vacinacoes.length,
                        itemBuilder: (context, index) {
                          final vacinacao = _vacinacoes[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.vaccines,
                                color: Color(0xFF064E2F),
                              ),
                              title: Text(_nomeAnimal(vacinacao.animalId)),
                              subtitle: Text(
                                'Vacina: ${vacinacao.vacina} | Aplicação: ${vacinacao.dataAplicacao} | Próxima dose: ${vacinacao.proximaDose?.isEmpty ?? true ? '-' : vacinacao.proximaDose}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _excluirVacinacao(vacinacao.id!);
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
              )
            ],
          ),
        ),
      ),
    );
  }
}