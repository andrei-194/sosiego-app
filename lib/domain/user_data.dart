/// Datos del usuario (favoritos, historial, racha, estado). Dart puro: la
/// implementación SQLite vive en data/user/ y la de memoria sirve a las pruebas.
library;

/// Un favorito: versículo y fecha en que se guardó.
class FavoriteEntry {
  const FavoriteEntry({required this.verseId, required this.createdAt});

  final int verseId;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is FavoriteEntry &&
      other.verseId == verseId &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(verseId, createdAt);
}

/// Una vez que se vio un versículo (spec §4: visible 2 s o más).
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.verseId,
    required this.seenAt,
  });

  final int id;
  final int verseId;
  final DateTime seenAt;
}

/// Cuántas entradas de historial se conservan (spec §6).
const historyKeepLimit = 2000;

/// Cuántas se listan en la vista «Vistos» (spec HU-10.2).
const historyListLimit = 100;

abstract interface class FavoritesRepository {
  /// Del más antiguo al más reciente.
  Future<List<FavoriteEntry>> list();

  /// Guarda el favorito. Con [createdAt] se restituye con su fecha original
  /// (deshacer, HU-10.3). Si ya existe, no cambia su fecha.
  Future<void> add(int verseId, {DateTime? createdAt});

  Future<void> remove(int verseId);
}

abstract interface class HistoryRepository {
  /// Registra que se vio [verseId] y recorta a [historyKeepLimit] entradas.
  Future<void> record(int verseId, {DateTime? at});

  /// Las últimas [limit] entradas, la más reciente primero.
  Future<List<HistoryEntry>> recent({int limit = historyListLimit});

  /// Ids de los últimos [limit] versículos vistos (para excluirlos del feed).
  Future<List<int>> recentVerseIds({int limit = 500});
}

abstract interface class ActivityRepository {
  /// Marca [day] (hora local) como día activo; repetirlo no hace nada.
  Future<void> markDay(DateTime day);

  /// Días activos como `YYYY-MM-DD`, los más recientes primero.
  Future<Set<String>> days({int limit = 400});
}

abstract interface class AppStateRepository {
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}

/// Claves de `app_state` (spec §6).
class AppStateKeys {
  static const installId = 'install_id';
  static const firstRunAt = 'first_run_at';
  static const contentVersionInstalled = 'content_version_installed';

  /// Marca de que ya se importó lo guardado en shared_preferences.
  static const legacyImported = 'legacy_prefs_imported';
}

/// `YYYY-MM-DD` en hora local, como se guarda en `activity_days`.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
