import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/feed_selector.dart';

List<FeedCandidate> _candidates() => [
  for (var i = 1; i <= 30; i++) FeedCandidate(i, i <= 20 ? 19 : 43),
];

void main() {
  test('no devuelve duplicados ni más de lo pedido', () {
    final s = FeedSelector(random: Random(1));
    final ids = s.pick(
      eligible: _candidates(),
      recentIds: [],
      lastBooks: [],
      count: 20,
    );
    expect(ids.length, 20);
    expect(ids.toSet().length, 20);
  });

  test('excluye los vistos recientemente', () {
    final s = FeedSelector(random: Random(2));
    final seen = List.generate(15, (i) => i + 1);
    final ids = s.pick(
      eligible: _candidates(),
      recentIds: seen,
      lastBooks: [],
      count: 15,
    );
    expect(ids.toSet().intersection(seen.toSet()), isEmpty);
  });

  test('como máximo 2 seguidos del mismo libro cuando hay alternativa', () {
    final s = FeedSelector(random: Random(3));
    final cands = _candidates();
    final byId = {for (final c in cands) c.id: c.bookId};
    final ids = s.pick(
      eligible: cands,
      recentIds: [],
      lastBooks: [19, 19],
      count: 12,
    );
    final books = [19, 19, ...ids.map((i) => byId[i]!)];
    for (var i = 2; i < books.length; i++) {
      final run = books[i] == books[i - 1] && books[i] == books[i - 2];
      expect(run, isFalse, reason: 'tres seguidos en posición $i');
    }
  });

  test('si casi todo se vio, reinicia en vez de devolver vacío', () {
    final s = FeedSelector(random: Random(4));
    final all = _candidates().map((c) => c.id).toList();
    final ids = s.pick(
      eligible: _candidates(),
      recentIds: all,
      lastBooks: [],
      count: 5,
    );
    expect(ids.length, 5);
  });

  test('con pocos elegibles devuelve los que haya', () {
    final s = FeedSelector(random: Random(5));
    final ids = s.pick(
      eligible: [const FeedCandidate(1, 19)],
      recentIds: [],
      lastBooks: [],
      count: 20,
    );
    expect(ids, [1]);
  });
}
