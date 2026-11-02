/// Converte um valor JSON para double.
///
/// Aceita números inteiros, decimais e textos numéricos.
/// Se não conseguir converter, retorna o valor padrão.
double jsonDouble(dynamic valor, [double padrao = 0.0]) {
  if (valor is num) {
    return valor.toDouble();
  }

  if (valor is String) {
    return double.tryParse(valor) ?? padrao;
  }

  return padrao;
}

/// Converte um valor JSON para double,
/// permitindo que o resultado seja null.
///
/// Útil para campos opcionais, como produção estimada.
double? jsonDoubleOuNulo(dynamic valor) {
  if (valor == null) return null;

  if (valor is num) {
    return valor.toDouble();
  }

  if (valor is String) {
    return double.tryParse(valor);
  }

  return null;
}

/// Converte um valor JSON para inteiro.
///
/// Se a conversão falhar, retorna o valor padrão.
int jsonInt(dynamic valor, [int padrao = 0]) {
  if (valor is int) return valor;

  if (valor is num) {
    return valor.toInt();
  }

  if (valor is String) {
    return int.tryParse(valor) ?? padrao;
  }

  return padrao;
}

/// Converte para inteiro, mas permite null.
///
/// Utilizado em campos opcionais, como safraId.
int? jsonIntOuNulo(dynamic valor) {
  if (valor == null) return null;

  if (valor is int) return valor;

  if (valor is num) {
    return valor.toInt();
  }

  if (valor is String) {
    return int.tryParse(valor);
  }

  return null;
}

/// Converte uma lista JSON em uma lista de mapas Dart.
List<Map<String, dynamic>> jsonLista(dynamic valor) {
  if (valor is! List) {
    return [];
  }

  return valor
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}
