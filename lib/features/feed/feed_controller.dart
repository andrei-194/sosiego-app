import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../domain/feed_selector.dart';

const _batchSize = 10;
const _historyLimit = 500;
const _prefsKey = 'recent_verse_ids';

/// Versículos ya mostrados en el feed, en orden. Crece al acercarse al final.
final feedControllerProvider =
    AsyncNotifierProvider<FeedController, List<Verse>>(FeedController.new);

class FeedController extends AsyncNotifier<List<Verse>> {
  final _selector = FeedSelector();
  late SharedPreferences _prefs;
  late List<int> _recent;
  List<FeedCandidate>? _eligible;
  bool _loading = false;

  @override
  Future<List<Verse>> build() async {
    _prefs = await SharedPreferences.getInstance();
    _recent = (_prefs.getStringList(_prefsKey) ?? []).map(int.parse).toList();
    return _nextBatch(const []);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || _loading) return;
    _loading = true;
    try {
      final more = await _nextBatch(current);
      state = AsyncData([...current, ...more]);
    } finally {
      _loading = false;
    }
  }

  Future<List<Verse>> _nextBatch(List<Verse> shown) async {
    final repo = await ref.read(contentRepositoryProvider.future);
    final eligible = _eligible ??= repo.eligibleCandidates();
    final ids = _selector.pick(
      eligible: eligible,
      recentIds: _recent,
      lastBooks: shown.map((v) => v.bookId).toList(),
      count: _batchSize,
    );
    _recent.addAll(ids);
    if (_recent.length > _historyLimit) {
      _recent.removeRange(0, _recent.length - _historyLimit);
    }
    await _prefs.setStringList(
      _prefsKey,
      _recent.map((id) => id.toString()).toList(),
    );
    return ids.map(repo.byId).whereType<Verse>().toList();
  }
}
