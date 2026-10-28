import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user/providers.dart';
import '../../domain/streak.dart';

/// Días con la app abierta. Registra hoy al crearse y expone la racha real
/// (`currentStreak`). Los días viven en user.db (`activity_days`).
final streakProvider = StateNotifierProvider<StreakNotifier, int>(
  StreakNotifier.new,
);

class StreakNotifier extends StateNotifier<int> {
  StreakNotifier(this._ref) : super(1) {
    _recordToday();
  }

  final Ref _ref;

  Future<void> _recordToday() async {
    try {
      final repo = await _ref.read(activityRepositoryProvider.future);
      final now = DateTime.now();
      await repo.markDay(now);
      final days = await repo.days();
      if (mounted) state = currentStreak(days, now);
    } catch (_) {}
  }
}
