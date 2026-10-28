import 'text_normalizer.dart';

/// Libro bíblico con su número canónico (1..66).
class BibleBook {
  const BibleBook(this.id, this.name, this.abbr);
  final int id;
  final String name;
  final String abbr;
}

/// Capítulos de cada libro (índice 0 = Génesis), para validar referencias.
const List<int> _builtInChapters = [
  50,
  40,
  27,
  36,
  34,
  24,
  21,
  4,
  31,
  24,
  22,
  25,
  29,
  36,
  10,
  13,
  10,
  42,
  150,
  31,
  12,
  8,
  66,
  52,
  5,
  48,
  12,
  14,
  3,
  9,
  1,
  4,
  7,
  3,
  3,
  3,
  2,
  14,
  4,
  28,
  16,
  24,
  21,
  28,
  16,
  16,
  13,
  6,
  6,
  4,
  4,
  5,
  3,
  6,
  4,
  3,
  1,
  13,
  5,
  5,
  3,
  5,
  1,
  1,
  1,
  22,
];

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

/// Clave de búsqueda de un nombre de libro: sin tildes, mayúsculas ni puntos,
/// y sin el espacio tras el número inicial («1 co» y «1co» son lo mismo).
String bookKey(String s) =>
    normalizeText(s)
        .replaceAll('.', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceFirstMapped(RegExp(r'^(\d) '), (m) => m.group(1)!);

/// Un libro con sus alias para resolver referencias (spec `books.aliases`).
class BookEntry {
  const BookEntry({
    required this.id,
    required this.name,
    required this.chapters,
    this.aliases = const [],
  });
  final int id;
  final String name;
  final int chapters;
  final List<String> aliases;
}

/// Índice nombre o alias -> libro. En la app lo arma `content.db`; el índice
/// integrado sirve a las pruebas de dominio.
class BookIndex {
  BookIndex(Iterable<BookEntry> books) {
    for (final b in books) {
      _chapters[b.id] = b.chapters;
      _byKey[bookKey(b.name)] = b.id;
      for (final a in b.aliases) {
        _byKey[bookKey(a)] = b.id;
      }
    }
  }

  factory BookIndex.builtIn() => BookIndex([
    for (final b in bibleBooks)
      BookEntry(
        id: b.id,
        name: b.name,
        chapters: _builtInChapters[b.id - 1],
        aliases: [
          b.abbr,
          for (final e in _extraAliases.entries)
            if (e.value == b.id) e.key,
        ],
      ),
  ]);

  final _byKey = <String, int>{};
  final _chapters = <int, int>{};

  int? lookup(String name) => _byKey[bookKey(name)];
  int? chaptersOf(int bookId) => _chapters[bookId];
}

final BookIndex _builtIn = BookIndex.builtIn();

/// Referencia a un versículo, un rango o un capítulo. `verse == null` es un
/// capítulo completo; `verseTo` cierra un rango («4-7»).
class VerseReference {
  const VerseReference(this.bookId, this.chapter, [this.verse, this.verseTo]);
  final int bookId;
  final int chapter;
  final int? verse;
  final int? verseTo;

  bool get isChapter => verse == null;
  bool get isRange => verse != null && verseTo != null && verseTo! > verse!;

  /// id compuesto: libro*1.000.000 + capítulo*1.000 + versículo.
  int? get verseId =>
      verse == null ? null : bookId * 1000000 + chapter * 1000 + verse!;

  @override
  bool operator ==(Object other) =>
      other is VerseReference &&
      other.bookId == bookId &&
      other.chapter == chapter &&
      other.verse == verse &&
      other.verseTo == verseTo;

  @override
  int get hashCode => Object.hash(bookId, chapter, verse, verseTo);

  @override
  String toString() => 'VerseReference($bookId, $chapter, $verse, $verseTo)';
}

final RegExp _refPattern = RegExp(
  r'^(.+?)\s*(\d{1,3})(?:(?:\s*[:.,]\s*|\s+)(\d{1,3})(?:\s*[-–—]\s*(\d{1,3}))?)?$',
);

/// Interpreta «Juan 3:16», «jn 3 16», «1 corintios 13:4-7», «salmo 23». Devuelve
/// null si no es una referencia reconocible o el capítulo no existe (la
/// búsqueda cae entonces al tema o al texto libre).
VerseReference? parseReference(String input, {BookIndex? index}) {
  final idx = index ?? _builtIn;
  final m = _refPattern.firstMatch(
    input.trim().replaceAll(RegExp(r'\s+'), ' '),
  );
  if (m == null) return null;
  final book = idx.lookup(m.group(1)!);
  if (book == null) return null;
  final chapter = int.parse(m.group(2)!);
  if (chapter < 1) return null;
  final max = idx.chaptersOf(book);
  if (max != null && chapter > max) return null;
  final verseStr = m.group(3);
  if (verseStr == null) return VerseReference(book, chapter);
  final verse = int.parse(verseStr);
  if (verse < 1) return null;
  final toStr = m.group(4);
  final to = toStr == null ? null : int.parse(toStr);
  if (to != null && to < verse) return null;
  return VerseReference(book, chapter, verse, to);
}
