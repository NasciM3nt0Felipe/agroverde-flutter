import 'package:flutter/material.dart';

import '../data/sqlite/propriedade_repository.dart';
import '../domain/entities/propriedade.dart';
import '../domain/services/sessao_service.dart';

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

  @override
  void dispose() {
    _nomeController.dispose();
    _areaTotalController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarPropriedade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final propriedade = Propriedade(
      usuarioId: SessaoService.usuarioId,
      nome: _nomeController.text,
      areaTotal: double.parse(_areaTotalController.text.replaceAll(',', '.')),
      cidade: _cidadeController.text,
      estado: _estadoController.text,
      descricao: _descricaoController.text,
    );

    await _propriedadeRepository.inserir(propriedade);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Propriedade cadastrada com sucesso!')),
    );

    _nomeController.clear();
    _areaTotalController.clear();
    _cidadeController.clear();
    _estadoController.clear();
    _descricaoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Propriedades')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 700,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        'Cadastro de Propriedade',
                        style: TextStyle(
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
                          if (value == null || value.isEmpty) {
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
                          if (value == null || value.isEmpty) {
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
                          child: const Text('Salvar Propriedade'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
