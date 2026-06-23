import 'package:agroverde/routes.dart';
import 'package:flutter/material.dart';

import '../data/sqlite/rebanho_repository.dart';
import '../domain/entities/animal.dart';
import '../domain/services/sessao_service.dart';
import 'historico_animal_page.dart';

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
  final _buscaController = TextEditingController();

  List<Animal> _animais = [];

  String _especieSelecionada = 'Bovino';
  String _sexoSelecionado = 'Macho';
  String _statusSelecionado = 'Ativo';
  String _filtroEspecie = 'Todos';
  String _ordenacaoSelecionada = 'Identificação';
  String? _loteSelecionado;
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
    _buscaController.dispose();
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

    final identificacao = _idEditando == null
        ? _gerarCodigoAnimal(_especieSelecionada)
        : _identificacaoController.text.trim();

    final pesoTexto = _pesoController.text.trim().replaceAll(',', '.');

    if (identificacao.isEmpty) {
      _mostrarMensagem('Não foi possível gerar a identificação do animal.');
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
      _mostrarMensagem('Animal cadastrado com sucesso. Código: $identificacao');
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Deseja realmente excluir este animal?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    await _repository.excluir(id);
    await _carregarAnimais();
    _mostrarMensagem('Animal excluído com sucesso.');
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

  List<Animal> get _animaisFiltrados {
    final busca = _buscaController.text.trim().toLowerCase();

    final filtrados = _animais.where((animal) {
      final identificacao = animal.identificacao.toLowerCase();
      final especie = animal.especie.toLowerCase();
      final raca = (animal.raca ?? '').toLowerCase();
      final sexo = animal.sexo.toLowerCase();
      final status = animal.status.toLowerCase();

      final bateBusca =
          busca.isEmpty ||
          identificacao.contains(busca) ||
          especie.contains(busca) ||
          raca.contains(busca) ||
          sexo.contains(busca) ||
          status.contains(busca);

      final bateEspecie =
          _filtroEspecie == 'Todos' || animal.especie == _filtroEspecie;

      final bateLote =
          _loteSelecionado == null ||
          _pertenceAoLote(animal, _loteSelecionado!);

      return bateBusca && bateEspecie && bateLote;
    }).toList();

    filtrados.sort((a, b) {
      switch (_ordenacaoSelecionada) {
        case 'Espécie':
          return a.especie.compareTo(b.especie);
        case 'Peso':
          return (b.peso ?? 0).compareTo(a.peso ?? 0);
        case 'Status':
          return a.status.compareTo(b.status);
        case 'Idade':
          final dataA = _converterDataNascimento(a.dataNascimento);
          final dataB = _converterDataNascimento(b.dataNascimento);
          if (dataA == null && dataB == null) return 0;
          if (dataA == null) return 1;
          if (dataB == null) return -1;
          return dataA.compareTo(dataB);
        case 'Identificação':
        default:
          return a.identificacao.compareTo(b.identificacao);
      }
    });

    return filtrados;
  }

  int _totalPorEspecie(String especie) {
    return _animais.where((animal) => animal.especie == especie).length;
  }

  int _totalBezerros() {
    return _animais.where((animal) {
      final data = _converterDataNascimento(animal.dataNascimento);

      if (data == null) return false;

      final meses =
          (DateTime.now().year - data.year) * 12 +
          (DateTime.now().month - data.month);

      return meses <= 12;
    }).length;
  }

  int _totalNovilhas() {
    return _animais.where((animal) {
      final data = _converterDataNascimento(animal.dataNascimento);

      if (data == null || animal.sexo != 'Fêmea') {
        return false;
      }

      final meses =
          (DateTime.now().year - data.year) * 12 +
          (DateTime.now().month - data.month);

      return meses > 12 && meses <= 24;
    }).length;
  }

  int _totalMatrizes() {
    return _animais.where((animal) {
      final data = _converterDataNascimento(animal.dataNascimento);

      if (data == null || animal.sexo != 'Fêmea') {
        return false;
      }

      final meses =
          (DateTime.now().year - data.year) * 12 +
          (DateTime.now().month - data.month);

      return meses > 24;
    }).length;
  }

  int _totalReprodutores() {
    return _animais.where((animal) {
      final data = _converterDataNascimento(animal.dataNascimento);

      if (data == null || animal.sexo != 'Macho') {
        return false;
      }

      final meses =
          (DateTime.now().year - data.year) * 12 +
          (DateTime.now().month - data.month);

      return meses > 24;
    }).length;
  }

  int _totalEngorda() {
    return _animais.where((animal) {
      return animal.peso != null &&
          animal.peso! >= 300 &&
          animal.status == 'Ativo';
    }).length;
  }

  bool _pertenceAoLote(Animal animal, String lote) {
    final data = _converterDataNascimento(animal.dataNascimento);

    if (data == null) return false;

    final meses =
        (DateTime.now().year - data.year) * 12 +
        (DateTime.now().month - data.month);

    switch (lote) {
      case 'Bezerros':
        return meses <= 12;

      case 'Novilhas':
        return animal.sexo == 'Fêmea' && meses > 12 && meses <= 24;

      case 'Matrizes':
        return animal.sexo == 'Fêmea' && meses > 24;

      case 'Reprodutores':
        return animal.sexo == 'Macho' && meses > 24;

      case 'Engorda':
        return animal.peso != null &&
            animal.peso! >= 300 &&
            animal.status == 'Ativo';

      default:
        return true;
    }
  }

  double _calcularPesoMedio() {
    final animaisComPeso = _animais
        .where((animal) => animal.peso != null)
        .toList();

    if (animaisComPeso.isEmpty) {
      return 0;
    }

    final soma = animaisComPeso.fold<double>(
      0,
      (total, animal) => total + (animal.peso ?? 0),
    );

    return soma / animaisComPeso.length;
  }

  String _codigoPrevisto() {
    if (_idEditando != null) {
      return _identificacaoController.text.trim();
    }

    return _gerarCodigoAnimal(_especieSelecionada);
  }

  String _abreviacaoEspecie(String especie) {
    switch (especie) {
      case 'Bovino':
        return 'BO';
      case 'Equino':
        return 'EQ';
      case 'Suíno':
        return 'SU';
      case 'Caprino':
        return 'CA';
      case 'Ovino':
        return 'OV';
      case 'Aves':
        return 'AV';
      default:
        return 'OU';
    }
  }

  String _gerarCodigoAnimal(String especie) {
    final prefixo = _abreviacaoEspecie(especie);
    int maiorNumero = 0;

    for (final animal in _animais) {
      if (animal.especie != especie) {
        continue;
      }

      final codigo = animal.identificacao.trim().toUpperCase();
      final regex = RegExp('^${RegExp.escape(prefixo)}-(\\d+)\$');
      final match = regex.firstMatch(codigo);

      if (match != null) {
        final numero = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (numero > maiorNumero) {
          maiorNumero = numero;
        }
      }
    }

    final proximoNumero = maiorNumero + 1;
    return '$prefixo-${proximoNumero.toString().padLeft(4, '0')}';
  }

  Color _corStatusFundo(String status) {
    switch (status) {
      case 'Ativo':
        return const Color(0xFFE8F5E9);
      case 'Vendido':
        return const Color(0xFFE3F2FD);
      case 'Abatido':
        return const Color(0xFFFFEBEE);
      case 'Transferido':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _corStatusTexto(String status) {
    switch (status) {
      case 'Ativo':
        return const Color(0xFF2E7D32);
      case 'Vendido':
        return const Color(0xFF1565C0);
      case 'Abatido':
        return const Color(0xFFC62828);
      case 'Transferido':
        return const Color(0xFFE65100);
      default:
        return const Color(0xFF616161);
    }
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _corStatusFundo(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _corStatusTexto(status), width: 0.7),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _corStatusTexto(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  DateTime? _converterDataNascimento(String? dataTexto) {
    if (dataTexto == null || dataTexto.trim().isEmpty) {
      return null;
    }

    try {
      final partes = dataTexto.split('/');

      if (partes.length != 3) {
        return null;
      }

      final dia = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final ano = int.parse(partes[2]);

      return DateTime(ano, mes, dia);
    } catch (e) {
      return null;
    }
  }

  String _calcularIdade(String? dataNascimento) {
    final nascimento = _converterDataNascimento(dataNascimento);

    if (nascimento == null) {
      return 'Não informada';
    }

    final hoje = DateTime.now();

    int anos = hoje.year - nascimento.year;
    int meses = hoje.month - nascimento.month;

    if (hoje.day < nascimento.day) {
      meses--;
    }

    if (meses < 0) {
      anos--;
      meses += 12;
    }

    if (anos < 0) {
      return 'Data inválida';
    }

    if (anos == 0 && meses == 0) {
      return 'Menos de 1 mês';
    }

    if (anos == 0) {
      return meses == 1 ? '1 mês' : '$meses meses';
    }

    if (meses == 0) {
      return anos == 1 ? '1 ano' : '$anos anos';
    }

    final textoAno = anos == 1 ? '1 ano' : '$anos anos';
    final textoMes = meses == 1 ? '1 mês' : '$meses meses';

    return '$textoAno e $textoMes';
  }

  @override
  Widget build(BuildContext context) {
    final propriedadeNome = SessaoService.propriedadeNome;
    final propriedadeSelecionada = SessaoService.propriedadeId != null;

    final totalAtivos = _animais.where((a) => a.status == 'Ativo').length;
    final totalVendidos = _animais.where((a) => a.status == 'Vendido').length;
    final totalAbatidos = _animais.where((a) => a.status == 'Abatido').length;
    final totalMachos = _animais.where((a) => a.sexo == 'Macho').length;
    final totalFemeas = _animais.where((a) => a.sexo == 'Fêmea').length;
    final pesoMedio = _calcularPesoMedio();

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
                    _IndicadorCard(
                      titulo: 'Machos',
                      valor: totalMachos.toString(),
                      icone: Icons.male,
                    ),
                    _IndicadorCard(
                      titulo: 'Fêmeas',
                      valor: totalFemeas.toString(),
                      icone: Icons.female,
                    ),
                    _IndicadorCard(
                      titulo: 'Peso médio',
                      valor: pesoMedio == 0
                          ? '-'
                          : '${pesoMedio.toStringAsFixed(1)} kg',
                      icone: Icons.monitor_weight,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Resumo por espécie',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ResumoEspecieCard(
                      especie: 'Bovinos',
                      quantidade: _totalPorEspecie('Bovino'),
                    ),
                    _ResumoEspecieCard(
                      especie: 'Equinos',
                      quantidade: _totalPorEspecie('Equino'),
                    ),
                    _ResumoEspecieCard(
                      especie: 'Suínos',
                      quantidade: _totalPorEspecie('Suíno'),
                    ),
                    _ResumoEspecieCard(
                      especie: 'Caprinos',
                      quantidade: _totalPorEspecie('Caprino'),
                    ),
                    _ResumoEspecieCard(
                      especie: 'Ovinos',
                      quantidade: _totalPorEspecie('Ovino'),
                    ),
                    _ResumoEspecieCard(
                      especie: 'Aves',
                      quantidade: _totalPorEspecie('Aves'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Lotes Automáticos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                if (_loteSelecionado != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Filtro ativo: $_loteSelecionado',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF064E2F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _loteSelecionado = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpar'),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _LoteAutomaticoCard(
                      titulo: 'Bezerros',
                      descricao: 'Animais até 12 meses',
                      quantidade: _totalBezerros(),
                      selecionado: _loteSelecionado == 'Bezerros',
                      onTap: () {
                        setState(() {
                          _loteSelecionado = 'Bezerros';
                        });
                      },
                    ),
                    _LoteAutomaticoCard(
                      titulo: 'Novilhas',
                      descricao: 'Fêmeas de 13 a 24 meses',
                      quantidade: _totalNovilhas(),
                      selecionado: _loteSelecionado == 'Novilhas',
                      onTap: () {
                        setState(() {
                          _loteSelecionado = 'Novilhas';
                        });
                      },
                    ),
                    _LoteAutomaticoCard(
                      titulo: 'Matrizes',
                      descricao: 'Fêmeas acima de 24 meses',
                      quantidade: _totalMatrizes(),
                      selecionado: _loteSelecionado == 'Matrizes',
                      onTap: () {
                        setState(() {
                          _loteSelecionado = 'Matrizes';
                        });
                      },
                    ),
                    _LoteAutomaticoCard(
                      titulo: 'Reprodutores',
                      descricao: 'Machos acima de 24 meses',
                      quantidade: _totalReprodutores(),
                      selecionado: _loteSelecionado == 'Reprodutores',
                      onTap: () {
                        setState(() {
                          _loteSelecionado = 'Reprodutores';
                        });
                      },
                    ),
                    _LoteAutomaticoCard(
                      titulo: 'Engorda',
                      descricao: 'Ativos com peso acima de 300 kg',
                      quantidade: _totalEngorda(),
                      selecionado: _loteSelecionado == 'Engorda',
                      onTap: () {
                        setState(() {
                          _loteSelecionado = 'Engorda';
                        });
                      },
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
                              hint: _idEditando == null
                                  ? 'Gerado automaticamente ao salvar'
                                  : null,
                              enabled: propriedadeSelecionada,
                              readOnly: _idEditando == null,
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

                        if (propriedadeSelecionada) ...[
                          const SizedBox(height: 12),
                          Text(
                            _idEditando == null
                                ? 'Código previsto: ${_codigoPrevisto()}'
                                : 'Editando código: ${_codigoPrevisto()}',
                            style: const TextStyle(
                              color: Color(0xFF064E2F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],

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

                TextField(
                  controller: _buscaController,
                  enabled: propriedadeSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar animal',
                    hintText:
                        'Digite identificação, espécie, raça, sexo ou status',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (valor) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: _filtroEspecie,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por espécie',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Todos',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'Bovino',
                            child: Text('Bovino'),
                          ),
                          DropdownMenuItem(
                            value: 'Equino',
                            child: Text('Equino'),
                          ),
                          DropdownMenuItem(
                            value: 'Suíno',
                            child: Text('Suíno'),
                          ),
                          DropdownMenuItem(
                            value: 'Caprino',
                            child: Text('Caprino'),
                          ),
                          DropdownMenuItem(
                            value: 'Ovino',
                            child: Text('Ovino'),
                          ),
                          DropdownMenuItem(value: 'Aves', child: Text('Aves')),
                          DropdownMenuItem(
                            value: 'Outro',
                            child: Text('Outro'),
                          ),
                        ],
                        onChanged: propriedadeSelecionada
                            ? (valor) {
                                setState(() {
                                  _filtroEspecie = valor!;
                                });
                              }
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: _ordenacaoSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Ordenar por',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Identificação',
                            child: Text('Identificação'),
                          ),
                          DropdownMenuItem(
                            value: 'Espécie',
                            child: Text('Espécie'),
                          ),
                          DropdownMenuItem(value: 'Peso', child: Text('Peso')),
                          DropdownMenuItem(
                            value: 'Idade',
                            child: Text('Idade'),
                          ),
                          DropdownMenuItem(
                            value: 'Status',
                            child: Text('Status'),
                          ),
                        ],
                        onChanged: propriedadeSelecionada
                            ? (valor) {
                                setState(() {
                                  _ordenacaoSelecionada = valor!;
                                });
                              }
                            : null,
                      ),
                    ),
                  ],
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
                    : _animaisFiltrados.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Nenhum animal encontrado na pesquisa.',
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _animaisFiltrados.length,
                        itemBuilder: (context, index) {
                          final animal = _animaisFiltrados[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.pets,
                                color: Color(0xFF064E2F),
                              ),
                              title: Text(
                                '${animal.identificacao} - ${animal.especie}',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Raça: ${animal.raca ?? '-'} | Idade: ${_calcularIdade(animal.dataNascimento)}',
                                  ),
                                  Text(
                                    'Sexo: ${animal.sexo} | Peso: ${animal.peso ?? '-'} kg',
                                  ),
                                  const SizedBox(height: 6),
                                  _statusChip(animal.status),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.history),
                                    tooltip: 'Histórico',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HistoricoAnimalPage(
                                            animal: animal,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      _editarAnimal(animal);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Excluir',
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
    bool readOnly = false,
  }) {
    return SizedBox(
      width: 250,
      child: TextField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
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

class _ResumoEspecieCard extends StatelessWidget {
  final String especie;
  final int quantidade;

  const _ResumoEspecieCard({required this.especie, required this.quantidade});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                especie,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                quantidade.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  color: Color(0xFF064E2F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoteAutomaticoCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final int quantidade;
  final bool selecionado;
  final VoidCallback onTap;

  const _LoteAutomaticoCard({
    required this.titulo,
    required this.descricao,
    required this.quantidade,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        elevation: selecionado ? 5 : 2,
        color: selecionado ? const Color(0xFFE8F5E9) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selecionado ? const Color(0xFF064E2F) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  descricao,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(
                  quantidade.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF064E2F),
                    fontWeight: FontWeight.bold,
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
