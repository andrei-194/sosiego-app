import 'package:sqlite3/sqlite3.dart';

import '../../domain/feed_selector.dart';
import '../../domain/text_normalizer.dart';

class Verse {
  const Verse({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });
  final int id;
  final int bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;

  String get reference => '$bookName $chapter:$verse';
}

/// Acceso de solo lectura a content.db.
class ContentRepository {
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

  String get contentVersion =>
      _db
              .select("SELECT value FROM meta WHERE key='content_version'")
              .first['value']
          as String;

  List<FeedCandidate> eligibleCandidates() => _db
      .select('SELECT id, book_id FROM verses WHERE is_card_eligible = 1')
      .map((r) => FeedCandidate(r['id'] as int, r['book_id'] as int))
      .toList();

  Verse? byId(int id) {
    final rows = _db.select('$_selectVerse WHERE v.id = ?', [id]);
    return rows.isEmpty ? null : _map(rows.first);
  }

  /// Todos los versículos de un capítulo, en orden (para "Contexto").
  List<Verse> chapterVerses(int bookId, int chapter) => _db
      .select(
        '$_selectVerse WHERE v.book_id = ? AND v.chapter = ? ORDER BY v.verse',
        [bookId, chapter],
      )
      .map(_map)
      .toList();

  /// Búsqueda de texto libre: cada palabra como prefijo, todas deben aparecer.
  List<Verse> search(String query, {int limit = 50}) {
    final tokens = normalizeText(query)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return const [];
    final match = tokens.map((t) => '$t*').join(' ');
    final rows = _db.select(
      '$_selectVerse JOIN verses_fts ON verses_fts.rowid = v.id '
      'WHERE verses_fts MATCH ? ORDER BY rank LIMIT ?',
      [match, limit],
    );
    return rows.map(_map).toList();
  }

  static const _selectVerse =
      'SELECT v.id, v.book_id, b.name AS book_name, v.chapter, v.verse, v.text '
      'FROM verses v JOIN books b ON b.id = v.book_id';

  Verse _map(Row r) => Verse(
    id: r['id'] as int,
    bookId: r['book_id'] as int,
    bookName: r['book_name'] as String,
    chapter: r['chapter'] as int,
    verse: r['verse'] as int,
    text: r['text'] as String,
  );
}
