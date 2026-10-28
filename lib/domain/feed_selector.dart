import 'dart:math';

/// Versículo candidato al feed (solo lo necesario para decidir).
class FeedCandidate {
  const FeedCandidate(this.id, this.bookId);
  final int id;
  final int bookId;
}

/// Selección del feed (spec §4): elegibles, sin repetir los últimos
/// [recentLimit] vistos y como máximo [maxSameBookRun] seguidos del mismo libro.
class FeedSelector {
  FeedSelector({
    Random? random,
    this.recentLimit = 500,
    this.maxSameBookRun = 2,
  }) : _random = random ?? Random();

  final Random _random;
  final int recentLimit;
  final int maxSameBookRun;

  /// Devuelve hasta [count] ids. [recentIds] va del más antiguo al más reciente;
  /// [lastBooks] son los libros de las últimas tarjetas mostradas (mismo orden).
  List<int> pick({
    required List<FeedCandidate> eligible,
    required List<int> recentIds,
    required List<int> lastBooks,
    required int count,
  }) {
    final recent = recentIds.length > recentLimit
        ? recentIds.sublist(recentIds.length - recentLimit).toSet()
        : recentIds.toSet();
    var pool = eligible.where((c) => !recent.contains(c.id)).toList();
    // Si casi todo se vio, se reinicia el historial en vez de dejar el feed vacío.
    if (pool.length < count) pool = List.of(eligible);
    pool.shuffle(_random);

    final result = <int>[];
    final books = List<int>.of(lastBooks);
    final used = <int>{};
    var guard = pool.length;
    final queue = List<FeedCandidate>.of(pool);

    while (result.length < count && queue.isNotEmpty && guard-- > 0) {
      final idx = queue.indexWhere((c) => !_breaksRun(books, c.bookId));
      final chosen = queue.removeAt(idx >= 0 ? idx : 0);
      if (!used.add(chosen.id)) continue;
      result.add(chosen.id);
      books.add(chosen.bookId);
    }
    return result;
  }

  bool _breaksRun(List<int> books, int bookId) {
    if (books.length < maxSameBookRun) return false;
    final tail = books.sublist(books.length - maxSameBookRun);
    return tail.every((b) => b == bookId);
  }
}
