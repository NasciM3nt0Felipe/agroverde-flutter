import 'package:flutter/material.dart';

import '../data/sqlite/pesagem_repository.dart';
import '../data/sqlite/reproducao_repository.dart';
import '../data/sqlite/sanitario_repository.dart';
import '../data/sqlite/vacinacao_repository.dart';
import '../domain/entities/animal.dart';
import '../domain/entities/pesagem_rebanho.dart';
import '../domain/entities/reproducao_rebanho.dart';
import '../domain/entities/sanitario_rebanho.dart';
import '../domain/entities/vacinacao_rebanho.dart';

import 'pesagem_page.dart';
import 'vacinacao_page.dart';
import 'sanitario_page.dart';
import 'reproducao_page.dart';

class HistoricoAnimalPage extends StatefulWidget {
  final Animal animal;

  const HistoricoAnimalPage({super.key, required this.animal});

  @override
  State<HistoricoAnimalPage> createState() => _HistoricoAnimalPageState();
}

class _HistoricoAnimalPageState extends State<HistoricoAnimalPage> {
  final PesagemRepository _pesagemRepository = PesagemRepository();
  final VacinacaoRepository _vacinacaoRepository = VacinacaoRepository();
  final SanitarioRepository _sanitarioRepository = SanitarioRepository();
  final ReproducaoRepository _reproducaoRepository = ReproducaoRepository();

  bool _carregando = true;

  List<PesagemRebanho> _pesagens = [];
  List<VacinacaoRebanho> _vacinacoes = [];
  List<SanitarioRebanho> _sanitarios = [];
  List<ReproducaoRebanho> _reproducoes = [];

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  // Carrega os históricos e indicadores do animal.
  Future<void> _carregarResumo() async {
    final animalId = widget.animal.id;

    if (animalId == null) {
      setState(() {
        _carregando = false;
      });
      return;
    }

    final pesagens = await _pesagemRepository.listarPorAnimal(animalId);
    final vacinacoes = await _vacinacaoRepository.listarPorAnimal(animalId);
    final sanitarios = await _sanitarioRepository.listarPorAnimal(animalId);
    final reproducoes = await _reproducaoRepository.listarPorAnimal(animalId);

    setState(() {
      _pesagens = pesagens;
      _vacinacoes = vacinacoes;
      _sanitarios = sanitarios;
      _reproducoes = reproducoes;
      _carregando = false;
    });
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

  /// Calcula a idade do animal com base na data de nascimento.
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

  /// Retorna informações da última pesagem registrada.
  String _ultimoPesoTexto() {
    if (_pesagens.isNotEmpty) {
      final ultima = _pesagens.first;
      return '${ultima.peso.toStringAsFixed(1)} kg em ${ultima.data}';
    }

    if (widget.animal.peso != null) {
      return '${widget.animal.peso!.toStringAsFixed(1)} kg';
    }

    return 'Não informado';
  }

  /// Retorna informações da última vacinação registrada.
  String _ultimaVacinaTexto() {
    if (_vacinacoes.isEmpty) {
      return 'Nenhuma vacina registrada';
    }

    final ultima = _vacinacoes.first;
    return '${ultima.vacina} em ${ultima.dataAplicacao}';
  }

  String _ultimoSanitarioTexto() {
    if (_sanitarios.isEmpty) {
      return 'Nenhum procedimento registrado';
    }

    final ultimo = _sanitarios.first;
    return '${ultimo.procedimento} em ${ultimo.data}';
  }

  String _ultimoReprodutivoTexto() {
    if (_reproducoes.isEmpty) {
      return 'Nenhum evento registrado';
    }

    final ultimo = _reproducoes.first;
    return '${ultimo.tipo} em ${ultimo.data}';
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico do Animal'),
        backgroundColor: const Color(0xFF064E2F),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  Text(
                    animal.identificacao,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${animal.especie} • ${animal.raca ?? "Raça não informada"}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                            'Ficha do Animal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LinhaFicha(
                            titulo: 'Identificação',
                            valor: animal.identificacao,
                          ),
                          _LinhaFicha(titulo: 'Espécie', valor: animal.especie),
                          _LinhaFicha(
                            titulo: 'Raça',
                            valor: animal.raca ?? '-',
                          ),
                          _LinhaFicha(titulo: 'Sexo', valor: animal.sexo),
                          _LinhaFicha(
                            titulo: 'Data de nascimento',
                            valor: animal.dataNascimento ?? '-',
                          ),
                          _LinhaFicha(
                            titulo: 'Idade',
                            valor: _calcularIdade(animal.dataNascimento),
                          ),
                          _LinhaFicha(
                            titulo: 'Peso cadastrado',
                            valor: animal.peso == null
                                ? '-'
                                : '${animal.peso!.toStringAsFixed(1)} kg',
                          ),
                          _LinhaFicha(titulo: 'Status', valor: animal.status),
                          if (animal.observacao != null &&
                              animal.observacao!.trim().isNotEmpty)
                            _LinhaFicha(
                              titulo: 'Observação',
                              valor: animal.observacao!,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Resumo do Animal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ResumoCard(
                        titulo: 'Último Peso',
                        valor: _ultimoPesoTexto(),
                        icone: Icons.monitor_weight,
                      ),
                      _ResumoCard(
                        titulo: 'Última Vacina',
                        valor: _ultimaVacinaTexto(),
                        icone: Icons.vaccines,
                      ),
                      _ResumoCard(
                        titulo: 'Último Procedimento',
                        valor: _ultimoSanitarioTexto(),
                        icone: Icons.medical_services,
                      ),
                      _ResumoCard(
                        titulo: 'Último Evento',
                        valor: _ultimoReprodutivoTexto(),
                        icone: Icons.favorite,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Estatísticas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ContadorCard(
                        titulo: 'Pesagens',
                        valor: _pesagens.length,
                      ),
                      _ContadorCard(
                        titulo: 'Vacinações',
                        valor: _vacinacoes.length,
                      ),
                      _ContadorCard(
                        titulo: 'Sanitário',
                        valor: _sanitarios.length,
                      ),
                      _ContadorCard(
                        titulo: 'Reprodução',
                        valor: _reproducoes.length,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Acessar Históricos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  _HistoricoCard(
                    icone: Icons.monitor_weight,
                    titulo: 'Histórico de Pesagens',
                    descricao: 'Registros de peso do animal.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PesagemPage(animal: animal),
                        ),
                      );
                    },
                  ),
                  _HistoricoCard(
                    icone: Icons.vaccines,
                    titulo: 'Histórico de Vacinação',
                    descricao: 'Vacinas aplicadas e próximas doses.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VacinacaoPage(animal: animal),
                        ),
                      );
                    },
                  ),
                  _HistoricoCard(
                    icone: Icons.medical_services,
                    titulo: 'Controle Sanitário',
                    descricao: 'Medicamentos e procedimentos realizados.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SanitarioPage(animal: animal),
                        ),
                      );
                    },
                  ),
                  _HistoricoCard(
                    icone: Icons.favorite,
                    titulo: 'Histórico Reprodutivo',
                    descricao: 'Cobertura, inseminação, prenhez e parto.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReproducaoPage(animal: animal),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _LinhaFicha extends StatelessWidget {
  final String titulo;
  final String valor;

  const _LinhaFicha({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$titulo:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: const Color(0xFF064E2F)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(valor),
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

class _ContadorCard extends StatelessWidget {
  final String titulo;
  final int valor;

  const _ContadorCard({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                valor.toString(),
                style: const TextStyle(
                  fontSize: 24,
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

class _HistoricoCard extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;

  const _HistoricoCard({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icone, color: const Color(0xFF064E2F)),
        title: Text(titulo),
        subtitle: Text(descricao),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
