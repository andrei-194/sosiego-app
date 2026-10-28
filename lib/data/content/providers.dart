import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'content_db_installer.dart';
import 'content_repository.dart';

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
