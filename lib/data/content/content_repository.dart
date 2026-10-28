import 'package:sqlite3/sqlite3.dart';

import '../../domain/content_models.dart';
import '../../domain/content_source.dart';
import '../../domain/feed_selector.dart';
import '../../domain/text_normalizer.dart';
import '../../domain/verse_reference.dart';

// `Verse` vive en el dominio; se reexporta para quien ya lo importaba de aquí.
export '../../domain/content_models.dart' show Verse;

/// Acceso de solo lectura a content.db (esquema v2 del spec §6).
class ContentRepository implements ContentSource {
  ContentRepository(String path)
    : _db = sqlite3.open(path, mode: OpenMode.readOnly);

  final Database _db;

  void close() => _db.dispose();

  /// FTS5 disponible en el SQLite empaquetado (prueba de fase 0).
  bool get hasFts5 =>
      _db
          .select("SELECT sqlite_compileoption_used('ENABLE_FTS5') AS v")
          .first['v'] ==
      1;

  String get contentVersion => meta('content_version') ?? '';

  @override
  String? meta(String key) {
    final rows = _db.select('SELECT value FROM meta WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  // ---- Versículos ---------------------------------------------------------

  @override
  List<FeedCandidate> eligibleCandidates() => _db
      .select('SELECT id, book_id FROM verses WHERE is_card_eligible = 1')
      .map((r) => FeedCandidate(r['id'] as int, r['book_id'] as int))
      .toList();

  @override
  Verse? byId(int id) {
    final rows = _db.select('$_selectVerse WHERE v.id = ?', [id]);
    return rows.isEmpty ? null : _verse(rows.first);
  }

  @override
  List<Verse> versesInRange(int bookId, int chapter, {int? from, int? to}) {
    final lo = from ?? 1;
    final hi = to ?? from ?? 1000;
    return _db
        .select(
          '$_selectVerse WHERE v.book_id = ? AND v.chapter = ? '
          'AND v.verse BETWEEN ? AND ? ORDER BY v.verse',
          [bookId, chapter, lo, hi],
        )
        .map(_verse)
        .toList();
  }

  BookIndex? _bookIndex;

  @override
  BookIndex get bookIndex => _bookIndex ??= BookIndex(
    _db
        .select('SELECT id, name_es, chapters, aliases FROM books')
        .map(
          (r) => BookEntry(
            id: r['id'] as int,
            name: r['name_es'] as String,
            chapters: r['chapters'] as int,
            aliases: (r['aliases'] as String)
                .split('|')
                .where((a) => a.isNotEmpty)
                .toList(),
          ),
        ),
  );

  // ---- Temas, momentos y modos del feed -----------------------------------

  @override
  List<Topic> themes({ThemeKind? kind}) => _db
      .select(
        'SELECT id, slug, name_es, kind, icon, sort FROM themes '
        '${kind == null ? '' : 'WHERE kind = ?'} ORDER BY sort',
        [if (kind != null) kind.name],
      )
      .map(_topic)
      .toList();

  @override
  Topic? themeBySlug(String slug) {
    final rows = _db.select(
      'SELECT id, slug, name_es, kind, icon, sort FROM themes WHERE slug = ?',
      [slug],
    );
    return rows.isEmpty ? null : _topic(rows.first);
  }

  @override
  List<Moment> moments() => _db
      .select(
        'SELECT id, slug, name_es, description, icon, sort FROM moments '
        'ORDER BY sort',
      )
      .map(_moment)
      .toList();

  @override
  Moment? momentBySlug(String slug) {
    final rows = _db.select(
      'SELECT id, slug, name_es, description, icon, sort FROM moments '
      'WHERE slug = ?',
      [slug],
    );
    return rows.isEmpty ? null : _moment(rows.first);
  }

  @override
  List<FeedCandidate> themeCandidates(int themeId, {double minWeight = 0.6}) =>
      _db
          .select(
            'SELECT vt.verse_id, v.book_id FROM verse_themes vt '
            'JOIN verses v ON v.id = vt.verse_id '
            'WHERE vt.theme_id = ? AND vt.weight >= ? '
            'ORDER BY vt.weight DESC, vt.verse_id',
            [themeId, minWeight],
          )
          .map((r) => FeedCandidate(r['verse_id'] as int, r['book_id'] as int))
          .toList();

  @override
  List<int> momentVerseIds(int momentId) => _db
      .select(
        'SELECT verse_id FROM moment_verses WHERE moment_id = ? ORDER BY rank',
        [momentId],
      )
      .map((r) => r['verse_id'] as int)
      .toList();

  @override
  List<int> similarIds(int verseId) => _db
      .select(
        'SELECT similar_id FROM verse_similar WHERE verse_id = ? ORDER BY rank',
        [verseId],
      )
      .map((r) => r['similar_id'] as int)
      .toList();

  // ---- Búsqueda ------------------------------------------------------------

  /// Palabras de [query] ya normalizadas (como `verses.text_norm`).
  static List<String> queryTokens(String query) =>
      normalizeText(query)
          .split(RegExp(r'[^a-z0-9]+'))
          .where((t) => t.isNotEmpty)
          .toList();

  /// Consulta FTS5: las palabras completas y prefijo solo en la última
  /// (spec HU-06.5), ordenada por `bm25`.
  @override
  List<Verse> searchText(String query, {int limit = 30}) {
    final tokens = queryTokens(query);
    if (tokens.isEmpty) return const [];
    final match = [
      for (var i = 0; i < tokens.length; i++)
        i == tokens.length - 1 ? '"${tokens[i]}"*' : '"${tokens[i]}"',
    ].join(' ');
    final rows = _db.select(
      '$_selectVerse JOIN verses_fts ON verses_fts.rowid = v.id '
      'WHERE verses_fts MATCH ? ORDER BY bm25(verses_fts), v.id LIMIT ?',
      [match, limit],
    );
    return rows.map(_verse).toList();
  }

  // ---- Día y reflexiones ----------------------------------------------------

  static String monthDay(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  ({int verseId, int? reflectionId})? dailyEntry(DateTime localDate) {
    final rows = _db.select(
      'SELECT verse_id, reflection_id FROM daily_calendar WHERE month_day = ?',
      [monthDay(localDate)],
    );
    if (rows.isEmpty) return null;
    return (
      verseId: rows.first['verse_id'] as int,
      reflectionId: rows.first['reflection_id'] as int?,
    );
  }

  /// Versículo del día para la fecha local (`MM-DD`, incluye el 02-29).
  Verse? dailyVerseFor(DateTime localDate) {
    final e = dailyEntry(localDate);
    return e == null ? null : byId(e.verseId);
  }

  static const _selectReflection =
      'SELECT id, verse_id, kind, theme_id, moment_id, context_text, '
      'reflection_text, application_text, prayer_text, reading_seconds, '
      'sensitive FROM reflections';

  @override
  Reflection? reflectionById(int id) {
    final rows = _db.select('$_selectReflection WHERE id = ?', [id]);
    return rows.isEmpty ? null : _reflection(rows.first);
  }

  @override
  List<Reflection> reflectionsForTheme(int themeId) => _db
      .select(
        "$_selectReflection WHERE kind = 'emotion' AND theme_id = ? ORDER BY id",
        [themeId],
      )
      .map(_reflection)
      .toList();

  @override
  List<Reflection> reflectionsForMoment(int momentId) => _db
      .select(
        "$_selectReflection WHERE kind = 'moment' AND moment_id = ? ORDER BY id",
        [momentId],
      )
      .map(_reflection)
      .toList();

  @override
  Reflection? reflectionForVerse(int verseId) {
    final rows = _db.select(
      '$_selectReflection WHERE verse_id = ? ORDER BY id LIMIT 1',
      [verseId],
    );
    return rows.isEmpty ? null : _reflection(rows.first);
  }

  // ---- Filas -> entidades -----------------------------------------------

  static const _selectVerse =
      'SELECT v.id, v.book_id, b.name_es AS book_name, b.slug AS book_slug, '
      'v.chapter, v.verse, v.text '
      'FROM verses v JOIN books b ON b.id = v.book_id';

  Verse _verse(Row r) => Verse(
    id: r['id'] as int,
    bookId: r['book_id'] as int,
    bookName: r['book_name'] as String,
    bookSlug: r['book_slug'] as String,
    chapter: r['chapter'] as int,
    verse: r['verse'] as int,
    text: r['text'] as String,
  );

  Topic _topic(Row r) => Topic(
    id: r['id'] as int,
    slug: r['slug'] as String,
    name: r['name_es'] as String,
    kind: r['kind'] == 'emotion' ? ThemeKind.emotion : ThemeKind.topic,
    icon: r['icon'] as String,
    sort: r['sort'] as int,
  );

  Moment _moment(Row r) => Moment(
    id: r['id'] as int,
    slug: r['slug'] as String,
    name: r['name_es'] as String,
    description: r['description'] as String,
    icon: r['icon'] as String,
    sort: r['sort'] as int,
  );

  Reflection _reflection(Row r) => Reflection(
    id: r['id'] as int,
    verseId: r['verse_id'] as int,
    kind: ReflectionKind.values.firstWhere((k) => k.name == r['kind']),
    themeId: r['theme_id'] as int?,
    momentId: r['moment_id'] as int?,
    contextText: r['context_text'] as String,
    reflectionText: r['reflection_text'] as String,
    applicationText: r['application_text'] as String,
    prayerText: r['prayer_text'] as String,
    readingSeconds: r['reading_seconds'] as int,
    sensitive: (r['sensitive'] as int) == 1,
  );
}
