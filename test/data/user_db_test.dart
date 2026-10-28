import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sosiego/data/user/legacy_import.dart';
import 'package:sosiego/data/user/memory_user_repositories.dart';
import 'package:sosiego/data/user/sqlite_user_repositories.dart';
import 'package:sosiego/data/user/user_db.dart';
import 'package:sosiego/domain/user_data.dart';
import 'package:sqlite3/sqlite3.dart';

Set<String> _tables(UserDb u) => u.db
    .select("SELECT name FROM sqlite_master WHERE type = 'table'")
    .map((r) => r['name'] as String)
    .toSet();

/// Las mismas comprobaciones para la implementación SQLite y la de memoria.
void _repositoryContract(
  String name,
  ({
    FavoritesRepository favorites,
    HistoryRepository history,
    ActivityRepository activity,
    AppStateRepository appState,
  })
  Function()
  make,
) {
  group('repositorios $name', () {
    late FavoritesRepository favorites;
    late HistoryRepository history;
    late ActivityRepository activity;
    late AppStateRepository appState;

    setUp(() {
      final r = make();
      favorites = r.favorites;
      history = r.history;
      activity = r.activity;
      appState = r.appState;
    });

    test('favoritos: guardar, listar de antiguo a nuevo y quitar', () async {
      await favorites.add(2, createdAt: DateTime(2026, 1, 2));
      await favorites.add(1, createdAt: DateTime(2026, 1, 1));
      await favorites.add(3, createdAt: DateTime(2026, 1, 3));
      expect((await favorites.list()).map((e) => e.verseId), [1, 2, 3]);
      await favorites.remove(2);
      expect((await favorites.list()).map((e) => e.verseId), [1, 3]);
    });

    test(
      'favoritos: deshacer restituye la fecha original y la posición',
      () async {
        await favorites.add(1, createdAt: DateTime(2026, 1, 1));
        await favorites.add(2, createdAt: DateTime(2026, 1, 2));
        await favorites.add(3, createdAt: DateTime(2026, 1, 3));
        await favorites.remove(2);
        await favorites.add(2, createdAt: DateTime(2026, 1, 2));
        final all = await favorites.list();
        expect(all.map((e) => e.verseId), [1, 2, 3]);
        expect(all[1].createdAt, DateTime(2026, 1, 2));
      },
    );

    test('favoritos: repetir no cambia la fecha', () async {
      await favorites.add(1, createdAt: DateTime(2026, 1, 1));
      await favorites.add(1, createdAt: DateTime(2026, 5, 5));
      expect((await favorites.list()).single.createdAt, DateTime(2026, 1, 1));
    });

    test('historial: lista los últimos 100, el más reciente primero', () async {
      final t0 = DateTime(2026, 3, 1);
      for (var i = 0; i < 150; i++) {
        await history.record(1000 + i, at: t0.add(Duration(minutes: i)));
      }
      final recent = await history.recent();
      expect(recent, hasLength(100));
      expect(recent.first.verseId, 1149);
      expect(recent.last.verseId, 1050);
      expect(await history.recentVerseIds(limit: 3), [1149, 1148, 1147]);
    });

    test('historial: conserva solo las últimas 2000', () async {
      final t0 = DateTime(2026, 3, 1);
      for (var i = 0; i < historyKeepLimit + 25; i++) {
        await history.record(i, at: t0.add(Duration(seconds: i)));
      }
      final all = await history.recent(limit: historyKeepLimit + 100);
      expect(all, hasLength(historyKeepLimit));
      expect(all.first.verseId, historyKeepLimit + 24);
      expect(all.last.verseId, 25);
    });

    test('actividad: un día solo cuenta una vez', () async {
      await activity.markDay(DateTime(2026, 2, 28));
      await activity.markDay(DateTime(2026, 2, 28, 23));
      await activity.markDay(DateTime(2026, 3, 1));
      expect(await activity.days(), {'2026-02-28', '2026-03-01'});
    });

    test('estado: guardar y reemplazar un valor', () async {
      expect(await appState.get('k'), isNull);
      await appState.set('k', 'a');
      await appState.set('k', 'b');
      expect(await appState.get('k'), 'b');
    });
  });
}

void main() {
  group('migraciones de user.db', () {
    test('una base nueva queda en la versión actual con las 4 tablas', () {
      final u = UserDb.inMemory();
      addTearDown(u.close);
      expect(u.version, userDbVersion);
      expect(
        _tables(u),
        containsAll(['favorites', 'history', 'activity_days', 'app_state']),
      );
    });

    test('el esquema es el del spec §6', () {
      final u = UserDb.inMemory();
      addTearDown(u.close);
      List<String> cols(String t) => u.db
          .select('PRAGMA table_info($t)')
          .map((r) => '${r['name']} ${r['type']}')
          .toList();
      expect(cols('favorites'), ['verse_id INTEGER', 'created_at INTEGER']);
      expect(cols('history'), [
        'id INTEGER',
        'verse_id INTEGER',
        'seen_at INTEGER',
      ]);
      expect(cols('activity_days'), ['day TEXT']);
      expect(cols('app_state'), ['key TEXT', 'value TEXT']);
      final idx = u.db
          .select("SELECT name FROM sqlite_master WHERE type = 'index'")
          .map((r) => r['name']);
      expect(idx, contains('idx_history_seen'));
    });

    test('abrir de nuevo no pierde datos ni repite migraciones', () {
      final dir = Directory.systemTemp.createTempSync('sosiego_userdb');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = p.join(dir.path, 'user.db');

      final a = UserDb.open(path);
      a.db.execute('INSERT INTO favorites VALUES (7, 123)');
      a.close();

      final b = UserDb.open(path);
      addTearDown(b.close);
      expect(b.version, userDbVersion);
      expect(
        b.db.select('SELECT verse_id FROM favorites').single['verse_id'],
        7,
      );
    });

    test('una migración que falla se revierte entera', () {
      final u = UserDb.inMemory();
      addTearDown(u.close);
      final rota = [
        ...userDbMigrations,
        const ['CREATE TABLE nueva (x)', 'ESTO NO ES SQL'],
      ];
      expect(() => u.migrate(rota), throwsA(isA<SqliteException>()));
      expect(u.version, userDbVersion);
      expect(_tables(u), isNot(contains('nueva')));
      // Una migración buena posterior sí se aplica.
      u.migrate([
        ...userDbMigrations,
        const ['ALTER TABLE favorites ADD COLUMN nota TEXT'],
      ]);
      expect(u.version, userDbVersion + 1);
    });

    test('una base más nueva que la app no se toca', () {
      final dir = Directory.systemTemp.createTempSync('sosiego_userdb');
      addTearDown(() => dir.deleteSync(recursive: true));
      final path = p.join(dir.path, 'user.db');
      final raw = sqlite3.open(path);
      raw.execute('PRAGMA user_version = ${userDbVersion + 5}');
      raw.dispose();

      final u = UserDb.open(path);
      addTearDown(u.close);
      expect(u.version, userDbVersion + 5);
      expect(_tables(u), isNot(contains('favorites')));
    });
  });

  _repositoryContract('SQLite', () {
    final u = UserDb.inMemory();
    addTearDown(u.close);
    return (
      favorites: SqliteFavoritesRepository(u),
      history: SqliteHistoryRepository(u),
      activity: SqliteActivityRepository(u),
      appState: SqliteAppStateRepository(u),
    );
  });

  _repositoryContract(
    'en memoria',
    () => (
      favorites: MemoryFavoritesRepository(),
      history: MemoryHistoryRepository(),
      activity: MemoryActivityRepository(),
      appState: MemoryAppStateRepository(),
    ),
  );

  group('importación única desde shared_preferences', () {
    test('trae favoritos (en orden) y días, y no se repite', () async {
      final u = UserDb.inMemory();
      addTearDown(u.close);
      final now = DateTime(2026, 10, 28, 12);
      const legacy = LegacyUserData(
        favoriteIds: [19023001, 43003016, 20003005],
        activeDays: ['2026-10-26', '2026-10-27', '2026-10-28'],
      );

      expect(importLegacyData(u, legacy, now: now), isTrue);
      final favs = await SqliteFavoritesRepository(u).list();
      expect(favs.map((e) => e.verseId), [19023001, 43003016, 20003005]);
      expect(favs.every((e) => !e.createdAt.isAfter(now)), isTrue);
      expect(await SqliteActivityRepository(u).days(), {
        '2026-10-26',
        '2026-10-27',
        '2026-10-28',
      });
      expect(
        await SqliteAppStateRepository(u).get(AppStateKeys.firstRunAt),
        isNotNull,
      );

      // Segunda vez: no duplica ni reaparece lo que se quitó después.
      await SqliteFavoritesRepository(u).remove(43003016);
      expect(importLegacyData(u, legacy, now: now), isFalse);
      expect(
        (await SqliteFavoritesRepository(u).list()).map((e) => e.verseId),
        [19023001, 20003005],
      );
    });

    test('sin datos viejos solo deja la marca', () {
      final u = UserDb.inMemory();
      addTearDown(u.close);
      expect(importLegacyData(u, const LegacyUserData()), isTrue);
      expect(importLegacyData(u, const LegacyUserData()), isFalse);
    });
  });
}
