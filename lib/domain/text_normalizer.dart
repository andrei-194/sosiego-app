/// Normaliza texto para búsqueda: minúsculas y sin tildes/diéresis/ñ.
/// Debe coincidir con `normalize()` del pipeline (make_sample_db.py) y con
/// el tokenizador `unicode61 remove_diacritics 2` de FTS5.
String normalizeText(String input) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}

/// Normalización completa de búsqueda: [normalizeText] y luego todo lo que no
/// es letra o número pasa a un espacio (los signos no cuentan). Es la forma de
/// `verses.text_norm` y de `tools/shared/normalize_cases.json`; la usan la
/// búsqueda y la resolución de temas para que ambas coincidan con el pipeline.
String normalizeSearchText(String input) =>
    normalizeText(input).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
