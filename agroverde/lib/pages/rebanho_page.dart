import 'package:agroverde/routes.dart';
import 'package:flutter/material.dart';


import '../data/sqlite/rebanho_repository.dart';
import '../domain/entities/animal.dart';

class RebanhoPage extends StatefulWidget {
  const RebanhoPage({super.key});

  @override
  State<RebanhoPage> createState() => _RebanhoPageState();
}

class _RebanhoPageState extends State<RebanhoPage> {
  final RebanhoRepository _repository = RebanhoRepository();

  final _identificacaoController = TextEditingController();
  final _especieController = TextEditingController();
  final _racaController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _pesoController = TextEditingController();
  final _observacaoController = TextEditingController();

  List<Animal> _animais = [];

  String _sexoSelecionado = 'Macho';
  String _statusSelecionado = 'Ativo';
  int? _idEditando;

  @override
  void initState() {
    super.initState();
    _carregarAnimais();
  }

  Future<void> _carregarAnimais() async {
    final dados = await _repository.listar();
    setState(() {
      _animais = dados;
    });
  }

  Future<void> _salvarAnimal() async {
    final identificacao = _identificacaoController.text.trim();
    final especie = _especieController.text.trim();
    final pesoTexto = _pesoController.text.trim().replaceAll(',', '.');

    if (identificacao.isEmpty || especie.isEmpty) {
      _mostrarMensagem('Preencha identificação e espécie.');
      return;
    }

    final animal = Animal(
      id: _idEditando,
      identificacao: identificacao,
      especie: especie,
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
      _especieController.text = animal.especie;
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
      _especieController.clear();
      _racaController.clear();
      _dataNascimentoController.clear();
      _pesoController.clear();
      _observacaoController.clear();
      _sexoSelecionado = 'Macho';
      _statusSelecionado = 'Ativo';
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            ),
                            _campoTexto(
                              controller: _especieController,
                              label: 'Espécie',
                            ),
                            _campoTexto(
                              controller: _racaController,
                              label: 'Raça',
                            ),
                            _campoTexto(
                              controller: _dataNascimentoController,
                              label: 'Data de nascimento',
                              hint: 'Ex: 10/06/2024',
                            ),
                            _campoTexto(
                              controller: _pesoController,
                              label: 'Peso',
                              keyboardType: TextInputType.number,
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
                                onChanged: (value) {
                                  setState(() {
                                    _sexoSelecionado = value!;
                                  });
                                },
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
                                onChanged: (value) {
                                  setState(() {
                                    _statusSelecionado = value!;
                                  });
                                },
                              ),
                            ),
                          ],
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

                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _salvarAnimal,
                              icon: Icon(
                                _idEditando == null ? Icons.save : Icons.edit,
                              ),
                              label: Text(
                                _idEditando == null
                                    ? 'Cadastrar'
                                    : 'Atualizar',
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

                _animais.isEmpty
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
  }) {
    return SizedBox(
      width: 250,
      child: TextField(
        controller: controller,
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
              )
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