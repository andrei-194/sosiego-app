import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/user_data.dart';
import 'legacy_import.dart';
import 'sqlite_user_repositories.dart';
import 'user_db.dart';

/// Abre user.db (app_flutter/user.db), aplica migraciones e importa una sola
/// vez lo que la fase 0 guardó en shared_preferences.
final userDbProvider = FutureProvider<UserDb>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final userDb = UserDb.open(p.join(dir.path, 'user.db'));
  ref.onDispose(userDb.close);
  await importLegacyPrefs(userDb);
  return userDb;
});

/// Los repositorios son interfaces de domain/: las pruebas los sustituyen por
/// las implementaciones en memoria con `overrideWith`.
final favoritesRepositoryProvider = FutureProvider<FavoritesRepository>(
  (ref) async =>
      SqliteFavoritesRepository(await ref.watch(userDbProvider.future)),
);

final historyRepositoryProvider = FutureProvider<HistoryRepository>(
  (ref) async =>
      SqliteHistoryRepository(await ref.watch(userDbProvider.future)),
);

final activityRepositoryProvider = FutureProvider<ActivityRepository>(
  (ref) async =>
      SqliteActivityRepository(await ref.watch(userDbProvider.future)),
);

final appStateRepositoryProvider = FutureProvider<AppStateRepository>(
  (ref) async =>
      SqliteAppStateRepository(await ref.watch(userDbProvider.future)),
);
