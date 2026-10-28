/// Texto y enlace que acompañan a una tarjeta compartida (spec §9, HU-09).
/// Dart puro: la dedicatoria solo existe aquí, en memoria; nunca va en el
/// enlace ni se guarda, se registra o se envía a ningún servidor.
library;

/// Dominio de los enlaces cortos. PENDIENTE: el dominio definitivo es una
/// decisión abierta (spec §13). La web de `web/` ya usa este mismo patrón
/// (`--site-url`, por defecto este valor). Es la ÚNICA constante: cámbiala aquí.
const shareDomainUrl = 'https://sosiego.app';

/// Largo máximo de la dedicatoria «Para:» (HU-09.1).
const maxDedicationLength = 30;

/// Slug de un libro a partir de su nombre («1 Corintios» → «1-corintios»).
/// Es la misma regla de `books.slug` en content.db: minúsculas, sin tildes y
/// guiones. Si el libro trae su propio slug, se usa ese.
String bookSlugFromName(String name) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final out = StringBuffer();
  for (final rune in name.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    out.write(i >= 0 ? to[i] : ch);
  }
  return out
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Enlace corto del versículo: `https://{dominio}/v/{slug}-{capitulo}-{versiculo}`.
/// El mismo para todas las personas: nunca lleva la dedicatoria.
String verseLink({
  required String bookSlug,
  required int chapter,
  required int verse,
  String domain = shareDomainUrl,
}) => '$domain/v/$bookSlug-$chapter-$verse';

/// Enlace sin esquema, para la tarjeta («sosiego.app/v/juan-3-16»).
String displayLink(String link) => link.replaceFirst(RegExp(r'^https?://'), '');

/// Limpia la dedicatoria: sin espacios sobrantes ni saltos de línea y con un
/// máximo de [maxDedicationLength] caracteres. Devuelve `null` si queda vacía.
String? cleanDedication(String? raw) {
  if (raw == null) return null;
  final collapsed = raw
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (collapsed.isEmpty) return null;
  final runes = collapsed.runes.toList();
  final cut = runes.length > maxDedicationLength
      ? String.fromCharCodes(runes.take(maxDedicationLength)).trim()
      : collapsed;
  return cut.isEmpty ? null : cut;
}

/// «Para mamá», la línea de dedicatoria (tarjeta y texto).
String dedicationLine(String name) => 'Para $name';

/// Formato del spec §9: «{texto}» / {referencia} / Para {nombre} (solo si
/// hay) / {enlace}.
String buildShareText({
  required String verseText,
  required String reference,
  required String link,
  String? dedication,
}) {
  final name = cleanDedication(dedication);
  return [
    '«$verseText»',
    reference,
    if (name != null) dedicationLine(name),
    link,
  ].join('\n');
}

/// `https://wa.me/?text=` con el texto codificado (espacios como `%20`, que
/// WhatsApp lee bien; `queryParameters` los pondría como `+`).
Uri whatsappUri(String text) =>
    Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
