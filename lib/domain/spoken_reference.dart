/// Texto hablado para «Escuchar» (HU-08.3). Dart puro.
library;

/// Libros cuyo ordinal es masculino («Primero de Samuel»); en las cartas es
/// femenino («Primera de Corintios»).
const _masculineBooks = {'samuel', 'reyes', 'cronicas'};

/// «Juan, capítulo 3, versículo 16». «1 Corintios» se dice «Primera de
/// Corintios» y «1 Samuel», «Primero de Samuel», para que la voz no lea «uno».
String spokenReference(String bookName, int chapter, int verse) =>
    '${spokenBookName(bookName)}, capítulo $chapter, versículo $verse';

String spokenBookName(String bookName) {
  final m = RegExp(r'^([123])\s+(.+)$').firstMatch(bookName.trim());
  if (m == null) return bookName.trim();
  final n = int.parse(m.group(1)!);
  final rest = m.group(2)!;
  final key = rest
      .toLowerCase()
      .replaceAll('ó', 'o')
      .replaceAll('é', 'e')
      .replaceAll('á', 'a');
  final masculine = _masculineBooks.contains(key);
  const fem = ['Primera', 'Segunda', 'Tercera'];
  const masc = ['Primero', 'Segundo', 'Tercero'];
  return '${(masculine ? masc : fem)[n - 1]} de $rest';
}

/// Bloques que se leen, en orden: referencia hablada, versículo y, si hay,
/// contexto, reflexión, aplicación y oración (los vacíos se omiten).
List<String> listenSegments({
  required String bookName,
  required int chapter,
  required int verse,
  required String verseText,
  List<String> extraBlocks = const [],
}) => [
  spokenReference(bookName, chapter, verse),
  verseText.trim(),
  for (final b in extraBlocks)
    if (b.trim().isNotEmpty) b.trim(),
];

/// Pausa entre bloques (HU-08.3).
const listenBlockPause = Duration(milliseconds: 500);

/// Velocidades de voz (HU-08.6): valores iniciales de `speechRate`, a calibrar
/// en un teléfono real.
enum VoiceSpeed {
  slow(0.4),
  normal(0.5),
  fast(0.6);

  const VoiceSpeed(this.rate);
  final double rate;

  /// La velocidad guardada (`tts_rate`) o, si no coincide, Normal.
  static VoiceSpeed fromRate(double? rate) => VoiceSpeed.values.firstWhere(
    (s) => rate != null && (s.rate - rate).abs() < 0.001,
    orElse: () => VoiceSpeed.normal,
  );
}

/// Idiomas de voz en orden de preferencia (HU-08.2).
const preferredVoiceLocales = ['es-CO', 'es-US', 'es-MX', 'es-ES'];

/// Voces en español del teléfono, de la más a la menos preferida: es-CO; si
/// no, es-US, es-MX o es-ES; y después cualquier otro es-XX. Acepta `es_CO` y
/// `es-CO`. Vacía si no hay voz en español (HU-08.7).
List<String> spanishLocaleCandidates(Iterable<String> available) {
  final byKey = <String, String>{
    for (final l in available) l.replaceAll('_', '-').toLowerCase(): l,
  };
  final out = <String>[];
  for (final want in preferredVoiceLocales) {
    final hit = byKey.remove(want.toLowerCase());
    if (hit != null) out.add(hit);
  }
  for (final e in byKey.entries) {
    if (e.key == 'es' || e.key.startsWith('es-')) out.add(e.value);
  }
  return out;
}

/// La mejor voz en español, o `null` si el teléfono no tiene ninguna.
String? pickSpanishLocale(Iterable<String> available) {
  final c = spanishLocaleCandidates(available);
  return c.isEmpty ? null : c.first;
}
