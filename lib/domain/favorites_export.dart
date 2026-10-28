/// Texto de «Enviarme mis guardados» (spec HU-10.6): referencia y versículo de
/// cada guardado, para compartir por la hoja del sistema como respaldo.
String buildFavoritesExport({
  required String header,
  required String footer,
  required List<({String reference, String text})> items,
}) {
  final b = StringBuffer(header);
  for (final i in items) {
    b
      ..write('\n\n')
      ..write(i.reference)
      ..write('\n«')
      ..write(i.text)
      ..write('»');
  }
  b
    ..write('\n\n')
    ..write(footer);
  return b.toString();
}
