import 'text_normalizer.dart';

/// Libro bíblico con su número canónico (1..66).
class BibleBook {
  const BibleBook(this.id, this.name, this.abbr);
  final int id;
  final String name;
  final String abbr;
}

const List<BibleBook> bibleBooks = [
  BibleBook(1, 'Génesis', 'Gn'),
  BibleBook(2, 'Éxodo', 'Ex'),
  BibleBook(3, 'Levítico', 'Lv'),
  BibleBook(4, 'Números', 'Nm'),
  BibleBook(5, 'Deuteronomio', 'Dt'),
  BibleBook(6, 'Josué', 'Jos'),
  BibleBook(7, 'Jueces', 'Jue'),
  BibleBook(8, 'Rut', 'Rt'),
  BibleBook(9, '1 Samuel', '1S'),
  BibleBook(10, '2 Samuel', '2S'),
  BibleBook(11, '1 Reyes', '1R'),
  BibleBook(12, '2 Reyes', '2R'),
  BibleBook(13, '1 Crónicas', '1Cr'),
  BibleBook(14, '2 Crónicas', '2Cr'),
  BibleBook(15, 'Esdras', 'Esd'),
  BibleBook(16, 'Nehemías', 'Neh'),
  BibleBook(17, 'Ester', 'Est'),
  BibleBook(18, 'Job', 'Job'),
  BibleBook(19, 'Salmos', 'Sal'),
  BibleBook(20, 'Proverbios', 'Pr'),
  BibleBook(21, 'Eclesiastés', 'Ec'),
  BibleBook(22, 'Cantares', 'Cnt'),
  BibleBook(23, 'Isaías', 'Is'),
  BibleBook(24, 'Jeremías', 'Jer'),
  BibleBook(25, 'Lamentaciones', 'Lm'),
  BibleBook(26, 'Ezequiel', 'Ez'),
  BibleBook(27, 'Daniel', 'Dn'),
  BibleBook(28, 'Oseas', 'Os'),
  BibleBook(29, 'Joel', 'Jl'),
  BibleBook(30, 'Amós', 'Am'),
  BibleBook(31, 'Abdías', 'Abd'),
  BibleBook(32, 'Jonás', 'Jon'),
  BibleBook(33, 'Miqueas', 'Miq'),
  BibleBook(34, 'Nahúm', 'Nah'),
  BibleBook(35, 'Habacuc', 'Hab'),
  BibleBook(36, 'Sofonías', 'Sof'),
  BibleBook(37, 'Hageo', 'Hag'),
  BibleBook(38, 'Zacarías', 'Zac'),
  BibleBook(39, 'Malaquías', 'Mal'),
  BibleBook(40, 'Mateo', 'Mt'),
  BibleBook(41, 'Marcos', 'Mr'),
  BibleBook(42, 'Lucas', 'Lc'),
  BibleBook(43, 'Juan', 'Jn'),
  BibleBook(44, 'Hechos', 'Hch'),
  BibleBook(45, 'Romanos', 'Ro'),
  BibleBook(46, '1 Corintios', '1Co'),
  BibleBook(47, '2 Corintios', '2Co'),
  BibleBook(48, 'Gálatas', 'Gal'),
  BibleBook(49, 'Efesios', 'Ef'),
  BibleBook(50, 'Filipenses', 'Fil'),
  BibleBook(51, 'Colosenses', 'Col'),
  BibleBook(52, '1 Tesalonicenses', '1Ts'),
  BibleBook(53, '2 Tesalonicenses', '2Ts'),
  BibleBook(54, '1 Timoteo', '1Ti'),
  BibleBook(55, '2 Timoteo', '2Ti'),
  BibleBook(56, 'Tito', 'Tit'),
  BibleBook(57, 'Filemón', 'Flm'),
  BibleBook(58, 'Hebreos', 'He'),
  BibleBook(59, 'Santiago', 'Stg'),
  BibleBook(60, '1 Pedro', '1P'),
  BibleBook(61, '2 Pedro', '2P'),
  BibleBook(62, '1 Juan', '1Jn'),
  BibleBook(63, '2 Juan', '2Jn'),
  BibleBook(64, '3 Juan', '3Jn'),
  BibleBook(65, 'Judas', 'Jud'),
  BibleBook(66, 'Apocalipsis', 'Ap'),
];

/// Alias frecuentes además del nombre y la abreviatura.
const Map<String, int> _extraAliases = {
  'salmo': 19,
  'cantar de los cantares': 22,
  'cantares': 22,
  'apocalipsis': 66,
  'hechos de los apostoles': 44,
};

final Map<String, int> _bookIndex = _buildIndex();

Map<String, int> _buildIndex() {
  final map = <String, int>{};
  for (final b in bibleBooks) {
    map[_key(b.name)] = b.id;
    map[_key(b.abbr)] = b.id;
  }
  _extraAliases.forEach((k, v) => map[_key(k)] = v);
  return map;
}

String _key(String s) =>
    normalizeText(s).replaceAll('.', '').replaceAll(RegExp(r'\s+'), ' ').trim();

/// Referencia a un versículo, capítulo o libro. `verse == null` => capítulo.
class VerseReference {
  const VerseReference(this.bookId, this.chapter, [this.verse]);
  final int bookId;
  final int chapter;
  final int? verse;

  /// id compuesto: libro*1.000.000 + capítulo*1.000 + versículo.
  int? get verseId =>
      verse == null ? null : bookId * 1000000 + chapter * 1000 + verse!;

  @override
  bool operator ==(Object other) =>
      other is VerseReference &&
      other.bookId == bookId &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(bookId, chapter, verse);

  @override
  String toString() => 'VerseReference($bookId, $chapter, $verse)';
}

final RegExp _refPattern = RegExp(
  r'^(.+?)\s+(\d{1,3})(?:\s*[:.,]\s*(\d{1,3}))?$',
);

/// Interpreta "Juan 3:16", "1 Cor 13", "sal. 23:1". Devuelve null si no es
/// una referencia reconocible (la búsqueda cae entonces a texto libre).
VerseReference? parseReference(String input) {
  final m = _refPattern.firstMatch(input.trim());
  if (m == null) return null;
  final book = _bookIndex[_key(m.group(1)!)];
  if (book == null) return null;
  final chapter = int.parse(m.group(2)!);
  final verseStr = m.group(3);
  if (chapter < 1) return null;
  final verse = verseStr == null ? null : int.parse(verseStr);
  if (verse != null && verse < 1) return null;
  return VerseReference(book, chapter, verse);
}
