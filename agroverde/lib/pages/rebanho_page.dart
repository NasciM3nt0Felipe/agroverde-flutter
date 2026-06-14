import 'package:agroverde/routes.dart';
import 'package:flutter/material.dart';

import '../data/sqlite/rebanho_repository.dart';
import '../domain/entities/animal.dart';
import '../domain/services/sessao_service.dart';

class RebanhoPage extends StatefulWidget {
  const RebanhoPage({super.key});

  @override
  State<RebanhoPage> createState() => _RebanhoPageState();
}

class _RebanhoPageState extends State<RebanhoPage> {
  final RebanhoRepository _repository = RebanhoRepository();

  final _identificacaoController = TextEditingController();
  final _racaController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _pesoController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Animal> _animais = [];

  String _especieSelecionada = 'Bovino';
  String _sexoSelecionado = 'Macho';
  String _statusSelecionado = 'Ativo';
  int? _idEditando;

  final List<String> _especies = const [
    'Bovino',
    'Equino',
    'Suíno',
    'Caprino',
    'Ovino',
    'Aves',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _carregarAnimais();
  }

  @override
  void dispose() {
    _identificacaoController.dispose();
    _racaController.dispose();
    _dataNascimentoController.dispose();
    _pesoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarAnimais() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      setState(() {
        _animais = [];
      });
      return;
    }

    final dados = await _repository.listarPorPropriedadeId(propriedadeId);

    setState(() {
      _animais = dados;
    });
  }

  Future<void> _selecionarDataNascimento() async {
    final dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (dataSelecionada == null) {
      return;
    }

    setState(() {
      _dataNascimentoController.text =
          '${dataSelecionada.day.toString().padLeft(2, '0')}/'
          '${dataSelecionada.month.toString().padLeft(2, '0')}/'
          '${dataSelecionada.year}';
    });
  }

  Future<void> _salvarAnimal() async {
    final propriedadeId = SessaoService.propriedadeId;

    if (propriedadeId == null) {
      _mostrarMensagem('Selecione uma propriedade em foco primeiro.');
      return;
    }

    final identificacao = _identificacaoController.text.trim();
    final pesoTexto = _pesoController.text.trim().replaceAll(',', '.');

    if (identificacao.isEmpty) {
      _mostrarMensagem('Preencha a identificação do animal.');
      return;
    }

    final animal = Animal(
      id: _idEditando,
      propriedadeId: propriedadeId,
      identificacao: identificacao,
      especie: _especieSelecionada,
      raca: _racaController.text.trim(),
      sexo: _sexoSelecionado,
      dataNascimento: _dataNascimentoController.text.trim(),
      peso: pesoTexto.isEmpty ? null : double.tryParse(pesoTexto),
      status: _statusSelecionado,
      observacao: _observacaoController.text.trim(),
    );

    if (_idEditando == null) {
      await _repository.inserir(animal);
      _mostrarMensagem('Animal cadastrado com sucesso.');
    } else {
      await _repository.atualizar(animal);
      _mostrarMensagem('Animal atualizado com sucesso.');
    }

    _limparCampos();
    await _carregarAnimais();
  }

  void _editarAnimal(Animal animal) {
    setState(() {
      _idEditando = animal.id;
      _identificacaoController.text = animal.identificacao;
      _especieSelecionada = animal.especie;
      _racaController.text = animal.raca ?? '';
      _sexoSelecionado = animal.sexo;
      _dataNascimentoController.text = animal.dataNascimento ?? '';
      _pesoController.text = animal.peso?.toString() ?? '';
      _statusSelecionado = animal.status;
      _observacaoController.text = animal.observacao ?? '';
    });
  }

  Future<void> _excluirAnimal(int id) async {
    await _repository.excluir(id);
    await _carregarAnimais();
    _mostrarMensagem('Animal excluído.');
  }

  void _limparCampos() {
    setState(() {
      _idEditando = null;
      _identificacaoController.clear();
      _racaController.clear();
      _dataNascimentoController.clear();
      _pesoController.clear();
      _observacaoController.clear();
      _especieSelecionada = 'Bovino';
      _sexoSelecionado = 'Macho';
      _statusSelecionado = 'Ativo';
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final propriedadeNome = SessaoService.propriedadeNome;
    final propriedadeSelecionada = SessaoService.propriedadeId != null;

    final totalAtivos = _animais.where((a) => a.status == 'Ativo').length;
    final totalVendidos = _animais.where((a) => a.status == 'Vendido').length;
    final totalAbatidos = _animais.where((a) => a.status == 'Abatido').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Rebanho'),
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
                  'Gestão do Rebanho',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  propriedadeNome == null
                      ? 'Selecione uma propriedade para gerenciar o rebanho.'
                      : 'Propriedade: $propriedadeNome',
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _IndicadorCard(
                      titulo: 'Total de animais',
                      valor: _animais.length.toString(),
                      icone: Icons.pets,
                    ),
                    _IndicadorCard(
                      titulo: 'Ativos',
                      valor: totalAtivos.toString(),
                      icone: Icons.check_circle,
                    ),
                    _IndicadorCard(
                      titulo: 'Vendidos',
                      valor: totalVendidos.toString(),
                      icone: Icons.sell,
                    ),
                    _IndicadorCard(
                      titulo: 'Abatidos',
                      valor: totalAbatidos.toString(),
                      icone: Icons.restaurant,
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
                        Text(
                          _idEditando == null
                              ? 'Inserir animal'
                              : 'Editar animal',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _campoTexto(
                              controller: _identificacaoController,
                              label: 'Identificação / Brinco',
                              enabled: propriedadeSelecionada,
                            ),

                            SizedBox(
                              width: 250,
                              child: DropdownButtonFormField<String>(
                                value: _especieSelecionada,
                                decoration: const InputDecoration(
                                  labelText: 'Espécie',
                                  border: OutlineInputBorder(),
                                ),
                                items: _especies
                                    .map(
                                      (especie) => DropdownMenuItem(
                                        value: especie,
                                        child: Text(especie),
                                      ),
                                    )
                                    .toList(),
                                onChanged: propriedadeSelecionada
                                    ? (value) {
                                        setState(() {
                                          _especieSelecionada = value!;
                                        });
                                      }
                                    : null,
                              ),
                            ),

                            _campoTexto(
                              controller: _racaController,
                              label: 'Raça',
                              enabled: propriedadeSelecionada,
                            ),

                            SizedBox(
                              width: 250,
                              child: TextField(
                                controller: _dataNascimentoController,
                                readOnly: true,
                                enabled: propriedadeSelecionada,
                                decoration: const InputDecoration(
                                  labelText: 'Data de nascimento',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_month),
                                ),
                                onTap: propriedadeSelecionada
                                    ? _selecionarDataNascimento
                                    : null,
                              ),
                            ),

                            _campoTexto(
                              controller: _pesoController,
                              label: 'Peso',
                              keyboardType: TextInputType.number,
                              enabled: propriedadeSelecionada,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 250,
                              child: DropdownButtonFormField<String>(
                                value: _sexoSelecionado,
                                decoration: const InputDecoration(
                                  labelText: 'Sexo',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Macho',
                                    child: Text('Macho'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Fêmea',
                                    child: Text('Fêmea'),
                                  ),
                                ],
                                onChanged: propriedadeSelecionada
                                    ? (value) {
                                        setState(() {
                                          _sexoSelecionado = value!;
                                        });
                                      }
                                    : null,
                              ),
                            ),

                            SizedBox(
                              width: 250,
                              child: DropdownButtonFormField<String>(
                                value: _statusSelecionado,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Ativo',
                                    child: Text('Ativo'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Vendido',
                                    child: Text('Vendido'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Abatido',
                                    child: Text('Abatido'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Transferido',
                                    child: Text('Transferido'),
                                  ),
                                ],
                                onChanged: propriedadeSelecionada
                                    ? (value) {
                                        setState(() {
                                          _statusSelecionado = value!;
                                        });
                                      }
                                    : null,
                              ),
                            ),
                          ],
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

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: propriedadeSelecionada
                                  ? _salvarAnimal
                                  : null,
                              icon: Icon(
                                _idEditando == null ? Icons.save : Icons.edit,
                              ),
                              label: Text(
                                _idEditando == null ? 'Cadastrar' : 'Atualizar',
                              ),
                            ),

                            const SizedBox(width: 12),

                            if (_idEditando != null)
                              OutlinedButton(
                                onPressed: _limparCampos,
                                child: const Text('Cancelar edição'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Controles do Rebanho',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                const Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ModuloControleCard(
                      titulo: 'Vacinação',
                      subtitulo: 'Controle de vacinas e próximas doses',
                      icone: Icons.vaccines,
                      rota: AppRoutes.vacinacao,
                    ),
                    _ModuloControleCard(
                      titulo: 'Controle Sanitário',
                      subtitulo: 'Medicamentos e procedimentos',
                      icone: Icons.medical_services,
                      rota: AppRoutes.sanitario,
                    ),
                    _ModuloControleCard(
                      titulo: 'Reprodução',
                      subtitulo: 'Cobertura, inseminação e gestação',
                      icone: Icons.favorite,
                      rota: AppRoutes.reproducao,
                    ),
                    _ModuloControleCard(
                      titulo: 'Pesagem',
                      subtitulo: 'Histórico de peso dos animais',
                      icone: Icons.monitor_weight,
                      rota: AppRoutes.pesagem,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Lista de animais',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                !propriedadeSelecionada
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Selecione uma propriedade para visualizar os animais.',
                            ),
                          ),
                        ),
                      )
                    : _animais.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Nenhum animal cadastrado.'),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _animais.length,
                        itemBuilder: (context, index) {
                          final animal = _animais[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.pets,
                                color: Color(0xFF064E2F),
                              ),
                              title: Text(
                                '${animal.identificacao} - ${animal.especie}',
                              ),
                              subtitle: Text(
                                'Raça: ${animal.raca ?? '-'} | Sexo: ${animal.sexo} | Peso: ${animal.peso ?? '-'} kg | Status: ${animal.status}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _editarAnimal(animal);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _excluirAnimal(animal.id!);
                                    },
                                  ),
                                ],
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

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return SizedBox(
      width: 250,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
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

class _ModuloControleCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final String? rota;

  const _ModuloControleCard({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    this.rota,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Card(
        child: ListTile(
          leading: Icon(icone, color: const Color(0xFF064E2F)),
          title: Text(titulo),
          subtitle: Text(subtitulo),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: rota == null
              ? null
              : () {
                  Navigator.pushNamed(context, rota!);
                },
        ),
      ),
    );
  }
}
