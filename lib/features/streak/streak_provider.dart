import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user/providers.dart';
import '../../domain/streak.dart';

/// Qué mostrar de la racha en Inicio (spec HU-11). Los días viven en user.db
/// (`activity_days`) y solo cuentan cuando se vio un versículo 2 segundos o
/// más (lo registra [seenRecorderProvider], no abrir la app).
final streakProvider = FutureProvider.autoDispose<StreakStatus>((ref) async {
  try {
    final repo = await ref.watch(activityRepositoryProvider.future);
    return streakStatus(await repo.days(), DateTime.now());
  } catch (_) {
    return StreakStatus.none;
  }
});
