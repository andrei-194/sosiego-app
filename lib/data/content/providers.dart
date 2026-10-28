import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/use_cases.dart';
import 'content_db_installer.dart';
import 'content_repository.dart';
import 'use_case_impls.dart';

/// Instala (o actualiza) content.db y abre el repositorio.
final contentRepositoryProvider = FutureProvider<ContentRepository>((
  ref,
) async {
  final dir = await getApplicationDocumentsDirectory();
  final installer = ContentDbInstaller(
    targetDir: dir.path,
    loadAsset: () async =>
        (await rootBundle.load('assets/db/content.db')).buffer.asUint8List(),
  );
  final path = await installer.ensureInstalled();
  final repo = ContentRepository(path);
  ref.onDispose(repo.close);
  return repo;
});

/// Casos de uso del dominio (spec §4) sobre la base ya abierta. La
/// presentación los pide por aquí y no toca SQLite.
final getNextVerseProvider = FutureProvider<GetNextVerse>(
  (ref) async =>
      GetNextVerseImpl(await ref.watch(contentRepositoryProvider.future)),
);

final searchVersesProvider = FutureProvider<SearchVerses>(
  (ref) async =>
      SearchVersesImpl(await ref.watch(contentRepositoryProvider.future)),
);

final getDailyContentProvider = FutureProvider<GetDailyContent>(
  (ref) async =>
      GetDailyContentImpl(await ref.watch(contentRepositoryProvider.future)),
);

final getCompanionProvider = FutureProvider<GetCompanion>(
  (ref) async =>
      GetCompanionImpl(await ref.watch(contentRepositoryProvider.future)),
);
