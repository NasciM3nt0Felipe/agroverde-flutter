# AgroVerde

Sistema de gestão rural desenvolvido em Flutter Desktop com banco de dados SQLite, criado para auxiliar produtores rurais no controle operacional, financeiro e produtivo da propriedade.

## Funcionalidades Implementadas

### Usuários e Perfil

* Cadastro e autenticação de usuários.
* Controle de perfil do usuário.
* Consulta automática de endereço via CEP.

### Propriedades

* Cadastro de propriedades rurais.
* Definição da propriedade em foco.
* Controle de área total da propriedade.

### Talhões e Safras

* Cadastro de talhões vinculados à propriedade.
* Controle de área cultivável.
* Cadastro de safras.
* Histórico de safras por talhão.
* Validação de apenas uma safra ativa por talhão.

### Estoque

* Cadastro de insumos e materiais.
* Controle de quantidade disponível.
* Controle de estoque mínimo.
* Controle por categoria.
* Consulta e filtros de estoque.

### Operações Agrícolas

* Registro de plantio.
* Registro de fertilização.
* Registro de pulverização.
* Controle de utilização de insumos por safra.

### Veículos

* Cadastro de veículos e máquinas.
* Controle de abastecimentos.
* Controle de manutenções.
* Registro de custos operacionais.

### Funcionários

* Cadastro de funcionários.
* Controle de admissão e desligamento.
* Controle salarial.
* Integração com o módulo financeiro.

### Financeiro

* Cadastro de receitas e despesas.
* Controle de fluxo financeiro.
* Integração automática com estoque, veículos e funcionários.
* Indicadores financeiros.

### Colheita

* Registro de colheitas.
* Controle de armazenagem de grãos.
* Registro de vendas.
* Atualização automática de receitas financeiras.

### Dashboard

* Indicadores da propriedade selecionada.
* Resumo financeiro.
* Resumo produtivo.
* Métricas operacionais.

## Tecnologias Utilizadas

* Flutter
* Dart
* SQLite
* sqflite_common_ffi
* Material Design

## Arquitetura

```text
lib/
├── data/
│   └── sqlite/
├── domain/
│   ├── entities/
│   └── services/
├── pages/
└── routes.dart
```

* Entities: representação dos dados.
* Repositories: acesso ao banco SQLite.
* Services: regras de negócio.
* Pages: interface do usuário.

## Execução

```bash
flutter pub get
flutter run
```

O banco de dados é criado automaticamente na primeira execução da aplicação.

## Autores

* Felipe do Nascimento Magalhães
* Gustavo Pereira Pedrosa
* Maicon do Amaral Barbosa

Instituto Federal do Sudeste de Minas Gerais - Campus Muriaé

Curso: Gestão da Tecnologia da Informação
