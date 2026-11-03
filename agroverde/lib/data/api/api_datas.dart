// Conversão de datas entre o formato do app (dd/MM/aaaa) e o da API
// (aaaa-MM-dd).

/// Converte "dd/MM/aaaa" (ou "aaaa-MM-dd") para "aaaa-MM-dd".
///
/// Lança [Exception] se o texto não for uma data válida.
String dataParaApi(String texto, {String campo = 'data'}) {
  final valor = texto.trim();

  final br = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(valor);
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(valor);

  int? dia, mes, ano;

  if (br != null) {
    dia = int.parse(br.group(1)!);
    mes = int.parse(br.group(2)!);
    ano = int.parse(br.group(3)!);
  } else if (iso != null) {
    ano = int.parse(iso.group(1)!);
    mes = int.parse(iso.group(2)!);
    dia = int.parse(iso.group(3)!);
  }

  if (dia == null || mes == null || ano == null) {
    throw Exception('Informe a $campo no formato dd/mm/aaaa.');
  }

  final data = DateTime(ano, mes, dia);

  if (data.year != ano || data.month != mes || data.day != dia) {
    throw Exception('A $campo informada não é válida.');
  }

  return '${ano.toString().padLeft(4, '0')}-'
      '${mes.toString().padLeft(2, '0')}-'
      '${dia.toString().padLeft(2, '0')}';
}

/// Converte "aaaa-MM-dd..." vindo da API para "dd/MM/aaaa".
/// Outros formatos são devolvidos sem alteração.
String dataDaApi(dynamic valor) {
  final texto = (valor ?? '').toString();
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(texto);

  if (iso == null) return texto;

  return '${iso.group(3)}/${iso.group(2)}/${iso.group(1)}';
}

/// Igual a [dataDaApi], mas preserva null.
String? dataDaApiOuNulo(dynamic valor) {
  if (valor == null || valor.toString().trim().isEmpty) return null;

  return dataDaApi(valor);
}

/// Texto opcional: vazio vira null.
String? textoOuNulo(String? valor) {
  if (valor == null || valor.trim().isEmpty) return null;

  return valor.trim();
}
