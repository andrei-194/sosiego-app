import '../../domain/user_data.dart';

/// Implementaciones en memoria de los repositorios del usuario (pruebas).

class MemoryFavoritesRepository implements FavoritesRepository {
  final _items = <int, DateTime>{};

  @override
  Future<List<FavoriteEntry>> list() async {
    final all = [
      for (final e in _items.entries)
        FavoriteEntry(verseId: e.key, createdAt: e.value),
    ];
    all.sort((a, b) {
      final c = a.createdAt.compareTo(b.createdAt);
      return c != 0 ? c : a.verseId.compareTo(b.verseId);
    });
    return all;
  }

  @override
  Future<void> add(int verseId, {DateTime? createdAt}) async =>
      _items.putIfAbsent(verseId, () => createdAt ?? DateTime.now());

  @override
  Future<void> remove(int verseId) async => _items.remove(verseId);
}

class MemoryHistoryRepository implements HistoryRepository {
  final _items = <HistoryEntry>[];
  var _nextId = 1;

  static int _newestFirst(HistoryEntry a, HistoryEntry b) {
    final c = b.seenAt.compareTo(a.seenAt);
    return c != 0 ? c : b.id.compareTo(a.id);
  }

  @override
  Future<void> record(int verseId, {DateTime? at}) async {
    _items.add(
      HistoryEntry(
        id: _nextId++,
        verseId: verseId,
        seenAt: at ?? DateTime.now(),
      ),
    );
    if (_items.length > historyKeepLimit) {
      _items.sort(_newestFirst);
      _items.removeRange(historyKeepLimit, _items.length);
    }
  }

  @override
  Future<List<HistoryEntry>> recent({int limit = historyListLimit}) async =>
      (List.of(_items)..sort(_newestFirst)).take(limit).toList();

  @override
  Future<List<int>> recentVerseIds({int limit = 500}) async =>
      (await recent(limit: limit)).map((e) => e.verseId).toList();
}

class MemoryActivityRepository implements ActivityRepository {
  final _days = <String>{};

  @override
  Future<void> markDay(DateTime day) async => _days.add(dayKey(day));

  @override
  Future<Set<String>> days({int limit = 400}) async =>
      (_days.toList()..sort((a, b) => b.compareTo(a))).take(limit).toSet();
}

class MemoryAppStateRepository implements AppStateRepository {
  final _values = <String, String>{};

  @override
  Future<String?> get(String key) async => _values[key];

  @override
  Future<void> set(String key, String value) async => _values[key] = value;
}
