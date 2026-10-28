import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';

/// Versículo por id (real, desde content.db).
final verseByIdProvider = FutureProvider.family<Verse?, int>((ref, id) async {
  final repo = await ref.watch(contentRepositoryProvider.future);
  return repo.byId(id);
});

/// Versión del contenido (tabla meta), para "Acerca de".
final contentVersionProvider = FutureProvider<String>((ref) async {
  final repo = await ref.watch(contentRepositoryProvider.future);
  return repo.contentVersion;
});
