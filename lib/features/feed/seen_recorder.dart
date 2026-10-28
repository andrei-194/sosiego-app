import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/user/providers.dart';
import '../streak/streak_provider.dart';

/// Registra un versículo visto: lo guarda en `history` y marca el día en
/// `activity_days` (spec §4.6 y HU-11.1). Quien lo llama espera antes los 2 s.
final seenRecorderProvider = Provider<SeenRecorder>(SeenRecorder.new);

class SeenRecorder {
  SeenRecorder(this._ref);
  final Ref _ref;

  Future<void> record(int verseId) async {
    try {
      final history = await _ref.read(historyRepositoryProvider.future);
      final activity = await _ref.read(activityRepositoryProvider.future);
      final now = DateTime.now();
      await history.record(verseId, at: now);
      await activity.markDay(now);
      _ref.invalidate(streakProvider);
    } catch (_) {
      // Sin base de usuario la app sigue funcionando; solo no se anota.
    }
  }
}

/// Cuenta [verseId] como visto cuando su [child] lleva visible 2 segundos
/// (spec §4.6). No cuenta si la pestaña no está a la vista.
class SeenAfterVisible extends ConsumerStatefulWidget {
  const SeenAfterVisible({
    super.key,
    required this.verseId,
    required this.child,
  });

  final int verseId;
  final Widget child;

  @override
  ConsumerState<SeenAfterVisible> createState() => _SeenAfterVisibleState();
}

class _SeenAfterVisibleState extends ConsumerState<SeenAfterVisible> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (TickerMode.valuesOf(context).enabled) {
      _timer = Timer(AppDuration.seen, () {
        if (mounted) ref.read(seenRecorderProvider).record(widget.verseId);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
