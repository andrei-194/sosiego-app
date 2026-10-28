import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../data/user/providers.dart';
import '../../domain/feed_mode.dart';
import '../../domain/use_cases.dart';

/// Versículos que la cola mantiene por delante del actual (spec §4.2).
const feedQueueAhead = 20;

/// Cuando quedan tantos por delante, se rellena con otros [feedQueueAhead].
const feedRefillAt = 5;

/// Cuántos versículos hacia atrás deja volver «Anterior» (spec §4.5).
const feedBackLimit = 100;

/// Margen antes de recortar la pila de atrás: se recorta en tandas de 10.
const feedTrimSlack = 10;

/// Cola de una sesión del feed: lo ya mostrado, el actual y lo que viene.
class FeedState {
  const FeedState({required this.items, this.cursor = 0, this.trimmed = 0});

  final List<Verse> items;

  /// Posición del versículo visible (o `items.length`, la tarjeta final).
  final int cursor;

  /// Cuántos versículos se han recortado del principio de la pila de atrás.
  final int trimmed;

  Verse? get current =>
      cursor >= 0 && cursor < items.length ? items[cursor] : null;
}

/// Un feed por modo (general, tema, momento o parecidos). Se descarta al salir
/// del modo, así cada entrada empieza una cola nueva.
final feedControllerProvider = AsyncNotifierProvider.autoDispose
    .family<FeedController, FeedState, FeedMode>(FeedController.new);

class FeedController
    extends AutoDisposeFamilyAsyncNotifier<FeedState, FeedMode> {
  late GetNextVerse _getNext;
  List<int> _recent = const [];

  @override
  Future<FeedState> build(FeedMode arg) async {
    _getNext = await ref.watch(getNextVerseProvider.future);
    try {
      final history = await ref.read(historyRepositoryProvider.future);
      _recent = await history.recentVerseIds();
    } catch (_) {
      _recent = const [];
    }
    final items = _getNext(
      FeedRequest(mode: arg, count: 1 + feedQueueAhead, recentIds: _recent),
    );
    return FeedState(items: items);
  }

  /// La persona llegó a la página [index]: rellena la cola y recorta la pila.
  void moveTo(int index) {
    final s = state.valueOrNull;
    if (s == null || index == s.cursor) return;
    var items = s.items;
    var cursor = index;
    var trimmed = s.trimmed;

    final ahead = items.length - 1 - cursor;
    if (ahead <= feedRefillAt && !arg.isFinite) {
      final more = _getNext(
        FeedRequest(
          mode: arg,
          count: feedQueueAhead,
          shownIds: items.map((v) => v.id).toList(),
          recentIds: _recent,
        ),
      );
      items = [...items, ...more];
    }
    if (cursor > feedBackLimit + feedTrimSlack) {
      final cut = cursor - feedBackLimit;
      items = items.sublist(cut);
      cursor -= cut;
      trimmed += cut;
    }
    state = AsyncData(
      FeedState(items: items, cursor: cursor, trimmed: trimmed),
    );
  }
}
