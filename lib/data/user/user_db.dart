import 'package:sqlite3/sqlite3.dart';

/// Migraciones de user.db, en orden. La posición `i` lleva de la versión `i`
/// a la `i + 1`; `PRAGMA user_version` guarda la versión alcanzada (spec §6).
/// Para cambiar el esquema, añade un elemento al final: nunca edites uno viejo.
const userDbMigrations = <List<String>>[
  // v1
  [
    '''
CREATE TABLE favorites (
  verse_id   INTEGER PRIMARY KEY,
  created_at INTEGER NOT NULL
)''',
    '''
CREATE TABLE history (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  verse_id INTEGER NOT NULL,
  seen_at  INTEGER NOT NULL
)''',
    'CREATE INDEX idx_history_seen ON history(seen_at DESC)',
    'CREATE TABLE activity_days (day TEXT PRIMARY KEY)',
    'CREATE TABLE app_state (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  ],
];

/// Versión actual del esquema de user.db.
int get userDbVersion => userDbMigrations.length;

/// user.db: se crea en el teléfono y se migra con `PRAGMA user_version`.
/// Se guarda en app_flutter/user.db: las reglas de respaldo de Android lo
/// incluyen y excluyen content.db (spec §11).
class UserDb {
  UserDb._(this.db);

  /// Abre (o crea) user.db en [path] y aplica las migraciones pendientes.
  factory UserDb.open(String path) => UserDb._(sqlite3.open(path))..migrate();

  /// Base en memoria, para pruebas.
  factory UserDb.inMemory() => UserDb._(sqlite3.openInMemory())..migrate();

  final Database db;

  int get version => db.select('PRAGMA user_version').first.values.first as int;

  /// Aplica en orden las migraciones que falten, cada una en su transacción.
  /// Si la base es más nueva que la app (respaldo de otra versión), no toca nada.
  void migrate([List<List<String>> migrations = userDbMigrations]) {
    for (var v = version; v < migrations.length; v++) {
      db.execute('BEGIN');
      try {
        for (final sql in migrations[v]) {
          db.execute(sql);
        }
        db.execute('PRAGMA user_version = ${v + 1}');
        db.execute('COMMIT');
      } catch (_) {
        db.execute('ROLLBACK');
        rethrow;
      }
    }
  }

  void close() => db.dispose();
}
