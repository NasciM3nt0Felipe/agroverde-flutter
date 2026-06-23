import 'package:flutter/material.dart';

import '../data/sqlite/estoque_repository.dart';
import '../data/sqlite/rebanho_repository.dart';
import '../data/sqlite/vacinacao_repository.dart';
import '../domain/entities/animal.dart';
import '../domain/entities/estoque_item.dart';
import '../domain/entities/vacinacao_rebanho.dart';
import '../domain/services/sessao_service.dart';
import '../domain/services/vacinacao_service.dart';

class VacinacaoPage extends StatefulWidget {
  final Animal? animal;

  const VacinacaoPage({super.key, this.animal});

  @override
  State<VacinacaoPage> createState() => _VacinacaoPageState();
}

class _VacinacaoPageState extends State<VacinacaoPage> {
  final VacinacaoRepository _vacinacaoRepository = VacinacaoRepository();
  final VacinacaoService _vacinacaoService = VacinacaoService();
  final RebanhoRepository _rebanhoRepository = RebanhoRepository();
  final EstoqueRepository _estoqueRepository = EstoqueRepository();

  final _dataAplicacaoController = TextEditingController();
  final _proximaDoseController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Animal> _animais = [];
  List<EstoqueItem> _vacinasDisponiveis = [];
  List<VacinacaoRebanho> _vacinacoes = [];

  int? _animalSelecionadoId;
  EstoqueItem? _vacinaSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _dataAplicacaoController.dispose();
    _proximaDoseController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      setState(() {
        _animais = [];
        _vacinasDisponiveis = [];
        _vacinacoes = [];
      });
      return;
    }

    final animais = await _rebanhoRepository.listarPorPropriedadeId(
      propriedadeId,
    );

    final vacinas = await _estoqueRepository
        .listarVacinasDisponiveisPorPropriedade(propriedadeId);

    final vacinacoes = await _vacinacaoRepository.listar();

    setState(() {
      _animais = animais;
      _vacinasDisponiveis = vacinas;

      if (widget.animal != null) {
        _animalSelecionadoId = widget.animal!.id;
      }

      final idsAnimaisDaPropriedade = animais.map((a) => a.id).toSet();

      _vacinacoes = vacinacoes
          .where((v) => idsAnimaisDaPropriedade.contains(v.animalId))
          .toList();

      if (_vacinaSelecionada != null &&
          !_vacinasDisponiveis.any((v) => v.id == _vacinaSelecionada!.id)) {
        _vacinaSelecionada = null;
      }
    });
  }

  Future<void> _salvarVacinacao() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      _mostrarMensagem('Selecione uma propriedade em foco primeiro.');
      return;
    }

    if (_animalSelecionadoId == null) {
      _mostrarMensagem('Selecione um animal.');
      return;
    }

    if (_vacinaSelecionada == null) {
      _mostrarMensagem('Selecione uma vacina disponível no estoque.');
      return;
    }

    final dataAplicacao = _dataAplicacaoController.text.trim();

    if (dataAplicacao.isEmpty) {
      _mostrarMensagem('Preencha a data de aplicação.');
      return;
    }

    final vacinacao = VacinacaoRebanho(
      animalId: _animalSelecionadoId!,
      vacina: _vacinaSelecionada!.nome,
      dataAplicacao: dataAplicacao,
      proximaDose: _proximaDoseController.text.trim(),
      observacao: _observacaoController.text.trim(),
    );

    try {
      await _vacinacaoService.registrarVacinacao(
        propriedadeId: propriedadeId,
        vacinacao: vacinacao,
      );

      setState(() {
        if (widget.animal == null) {
          _animalSelecionadoId = null;
        }
        _vacinaSelecionada = null;
      });

      _dataAplicacaoController.clear();
      _proximaDoseController.clear();
      _observacaoController.clear();

      await _carregarDados();

      _mostrarMensagem('Vacinação registrada com sucesso.');
    } catch (e) {
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''));
    }
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

  List<VacinacaoRebanho> get _vacinacoesFiltradas {
    if (_animalSelecionadoId == null) {
      return _vacinacoes;
    }

    return _vacinacoes
        .where((vacinacao) => vacinacao.animalId == _animalSelecionadoId)
        .toList();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final propriedadeSelecionada = SessaoService.propriedadeId != null;
    final propriedadeNome = SessaoService.propriedadeNome;

    final vacinasComProximaDose = _vacinacoesFiltradas
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

                const SizedBox(height: 8),

                Text(
                  propriedadeNome == null
                      ? 'Selecione uma propriedade para gerenciar as vacinações.'
                      : 'Propriedade: $propriedadeNome',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _IndicadorCard(
                      titulo: 'Registros',
                      valor: _vacinacoesFiltradas.length.toString(),
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

                        DropdownButtonFormField<int>(
                          value: _animalSelecionadoId,
                          decoration: const InputDecoration(
                            labelText: 'Animal',
                            border: OutlineInputBorder(),
                          ),
                          items: _animais.map((animal) {
                            return DropdownMenuItem<int>(
                              value: animal.id,
                              child: Text(
                                '${animal.identificacao} - ${animal.especie}',
                              ),
                            );
                          }).toList(),
                          onChanged: propriedadeSelecionada
                              ? (id) {
                                  setState(() {
                                    _animalSelecionadoId = id;
                                  });
                                }
                              : null,
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<int>(
                          value: _vacinaSelecionada?.id,
                          decoration: const InputDecoration(
                            labelText: 'Vacina em estoque',
                            border: OutlineInputBorder(),
                          ),
                          items: _vacinasDisponiveis.map((vacina) {
                            return DropdownMenuItem<int>(
                              value: vacina.id,
                              child: Text(
                                '${vacina.nome} - ${vacina.quantidadeAtual.toStringAsFixed(0)} ${vacina.unidadeMedida}',
                              ),
                            );
                          }).toList(),
                          onChanged: propriedadeSelecionada
                              ? (id) {
                                  setState(() {
                                    _vacinaSelecionada = _vacinasDisponiveis
                                        .where((v) => v.id == id)
                                        .firstOrNull;
                                  });
                                }
                              : null,
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _dataAplicacaoController,
                          enabled: propriedadeSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Data de aplicação',
                            hintText: 'Ex: 13/06/2026',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _proximaDoseController,
                          enabled: propriedadeSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Próxima dose',
                            hintText: 'Ex: 13/12/2026',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _observacaoController,
                          enabled: propriedadeSelecionada,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Observação',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        if (propriedadeSelecionada &&
                            _vacinasDisponiveis.isEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Nenhuma vacina disponível no estoque desta propriedade.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],

                        const SizedBox(height: 16),

                        ElevatedButton.icon(
                          onPressed: propriedadeSelecionada
                              ? _salvarVacinacao
                              : null,
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

                !propriedadeSelecionada
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Selecione uma propriedade para visualizar as vacinações.',
                            ),
                          ),
                        ),
                      )
                    : _vacinacoesFiltradas.isEmpty
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
                        itemCount: _vacinacoesFiltradas.length,
                        itemBuilder: (context, index) {
                          final vacinacao = _vacinacoesFiltradas[index];

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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
