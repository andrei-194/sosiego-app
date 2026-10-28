import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/user_data.dart';
import 'user_db.dart';

/// Claves donde la fase 0 guardaba favoritos y días activos.
const legacyFavoritesKey = 'favorite_verse_ids';
const legacyActiveDaysKey = 'active_days';

/// Lo que había en shared_preferences antes de existir user.db.
class LegacyUserData {
  const LegacyUserData({
    this.favoriteIds = const [],
    this.activeDays = const [],
  });

  /// Del más antiguo al más reciente (el orden en que se guardaron).
  final List<int> favoriteIds;

  /// `YYYY-MM-DD`.
  final List<String> activeDays;

  bool get isEmpty => favoriteIds.isEmpty && activeDays.isEmpty;

  static LegacyUserData fromPrefs(SharedPreferences p) => LegacyUserData(
    favoriteIds: (p.getStringList(legacyFavoritesKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toList(),
    activeDays: (p.getStringList(legacyActiveDaysKey) ?? const [])
        .where((d) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d))
        .toList(),
  );
}

/// Importación única a user.db. Si ya se hizo (`app_state`), no hace nada.
/// Va en una sola transacción: o entra todo o no entra nada. Devuelve `true`
/// si importó en esta llamada.
bool importLegacyData(UserDb userDb, LegacyUserData data, {DateTime? now}) {
  final db = userDb.db;
  final done = db.select('SELECT 1 FROM app_state WHERE key = ?', [
    AppStateKeys.legacyImported,
  ]);
  if (done.isNotEmpty) return false;

  final ts = (now ?? DateTime.now()).millisecondsSinceEpoch;
  db.execute('BEGIN');
  try {
    // Sin fecha original: se escalona de a 1 ms hasta ahora para conservar
    // el orden en que se guardaron.
    final n = data.favoriteIds.length;
    for (var i = 0; i < n; i++) {
      db.execute(
        'INSERT OR IGNORE INTO favorites (verse_id, created_at) VALUES (?, ?)',
        [data.favoriteIds[i], ts - (n - i)],
      );
    }
    for (final d in data.activeDays) {
      db.execute('INSERT OR IGNORE INTO activity_days (day) VALUES (?)', [d]);
    }
    db.execute('INSERT OR IGNORE INTO app_state (key, value) VALUES (?, ?)', [
      AppStateKeys.firstRunAt,
      ts.toString(),
    ]);
    db.execute('INSERT INTO app_state (key, value) VALUES (?, ?)', [
      AppStateKeys.legacyImported,
      '1',
    ]);
    db.execute('COMMIT');
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
  return true;
}

/// Lee shared_preferences, importa a [userDb] y, solo si salió bien, borra las
/// claves viejas para que no queden dos fuentes de verdad.
Future<void> importLegacyPrefs(UserDb userDb) async {
  final prefs = await SharedPreferences.getInstance();
  final imported = importLegacyData(userDb, LegacyUserData.fromPrefs(prefs));
  if (imported) {
    await prefs.remove(legacyFavoritesKey);
    await prefs.remove(legacyActiveDaysKey);
  }
}
