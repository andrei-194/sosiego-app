import 'package:sqlite3/sqlite3.dart';

import '../../domain/user_data.dart';
import 'user_db.dart';

DateTime _at(Object? ms) => DateTime.fromMillisecondsSinceEpoch(ms as int);

class SqliteFavoritesRepository implements FavoritesRepository {
  SqliteFavoritesRepository(this._userDb);
  final UserDb _userDb;
  Database get _db => _userDb.db;

  @override
  Future<List<FavoriteEntry>> list() async => _db
      .select(
        'SELECT verse_id, created_at FROM favorites '
        'ORDER BY created_at, verse_id',
      )
      .map(
        (r) => FavoriteEntry(
          verseId: r['verse_id'] as int,
          createdAt: _at(r['created_at']),
        ),
      )
      .toList();

  @override
  Future<void> add(int verseId, {DateTime? createdAt}) async {
    _db.execute(
      'INSERT OR IGNORE INTO favorites (verse_id, created_at) VALUES (?, ?)',
      [verseId, (createdAt ?? DateTime.now()).millisecondsSinceEpoch],
    );
  }

  @override
  Future<void> remove(int verseId) async =>
      _db.execute('DELETE FROM favorites WHERE verse_id = ?', [verseId]);
}

class SqliteHistoryRepository implements HistoryRepository {
  SqliteHistoryRepository(this._userDb);
  final UserDb _userDb;
  Database get _db => _userDb.db;

  @override
  Future<void> record(int verseId, {DateTime? at}) async {
    _db.execute('INSERT INTO history (verse_id, seen_at) VALUES (?, ?)', [
      verseId,
      (at ?? DateTime.now()).millisecondsSinceEpoch,
    ]);
    // Conserva solo las últimas entradas (spec §6).
    _db.execute(
      'DELETE FROM history WHERE id NOT IN '
      '(SELECT id FROM history ORDER BY seen_at DESC, id DESC LIMIT ?)',
      [historyKeepLimit],
    );
  }

  @override
  Future<List<HistoryEntry>> recent({int limit = historyListLimit}) async => _db
      .select(
        'SELECT id, verse_id, seen_at FROM history '
        'ORDER BY seen_at DESC, id DESC LIMIT ?',
        [limit],
      )
      .map(
        (r) => HistoryEntry(
          id: r['id'] as int,
          verseId: r['verse_id'] as int,
          seenAt: _at(r['seen_at']),
        ),
      )
      .toList();

  @override
  Future<List<int>> recentVerseIds({int limit = 500}) async =>
      (await recent(limit: limit)).map((e) => e.verseId).toList();
}

class SqliteActivityRepository implements ActivityRepository {
  SqliteActivityRepository(this._userDb);
  final UserDb _userDb;
  Database get _db => _userDb.db;

  @override
  Future<void> markDay(DateTime day) async => _db.execute(
    'INSERT OR IGNORE INTO activity_days (day) VALUES (?)',
    [dayKey(day)],
  );

  @override
  Future<Set<String>> days({int limit = 400}) async => _db
      .select('SELECT day FROM activity_days ORDER BY day DESC LIMIT ?', [
        limit,
      ])
      .map((r) => r['day'] as String)
      .toSet();
}

class SqliteAppStateRepository implements AppStateRepository {
  SqliteAppStateRepository(this._userDb);
  final UserDb _userDb;
  Database get _db => _userDb.db;

  @override
  Future<String?> get(String key) async {
    final rows = _db.select('SELECT value FROM app_state WHERE key = ?', [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  @override
  Future<void> set(String key, String value) async => _db.execute(
    'INSERT INTO app_state (key, value) VALUES (?, ?) '
    'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [key, value],
  );
}
