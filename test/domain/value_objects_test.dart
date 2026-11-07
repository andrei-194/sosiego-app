import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/content_models.dart';
import 'package:sosiego/domain/feed_mode.dart';
import 'package:sosiego/domain/feed_selector.dart';
import 'package:sosiego/domain/user_data.dart';
import 'package:sosiego/domain/verse_reference.dart';

/// Igualdad, hash y texto de los objetos de valor del dominio (cobertura de
/// `domain/`, puerta 3 del spec 10).
void main() {
  test('FeedMode: igualdad, hash, toString y modos finitos', () {
    expect(const FeedMode.theme('paz'), const FeedMode.theme('paz'));
    expect(const FeedMode.theme('paz'), isNot(const FeedMode.moment('paz')));
    expect(
      const FeedMode.similar(3).hashCode,
      const FeedMode.similar(3).hashCode,
    );
    expect(const FeedMode.similar(3).toString(), contains('similar'));
    expect(FeedMode.general.isFinite, isFalse);
    expect(const FeedMode.theme('paz').isFinite, isFalse);
    expect(const FeedMode.moment('noche').isFinite, isTrue);
    expect(const FeedMode.similar(3).isFinite, isTrue);
  });

  test('FavoriteEntry: igualdad y hash por versículo y fecha', () {
    final d = DateTime(2026, 10, 28);
    final a = FavoriteEntry(verseId: 1, createdAt: d);
    expect(a, FavoriteEntry(verseId: 1, createdAt: d));
    expect(a.hashCode, FavoriteEntry(verseId: 1, createdAt: d).hashCode);
    expect(a, isNot(FavoriteEntry(verseId: 2, createdAt: d)));
  });

  test('HistoryEntry conserva sus campos y los límites son los del spec', () {
    final e = HistoryEntry(id: 1, verseId: 2, seenAt: DateTime(2026));
    expect((e.id, e.verseId), (1, 2));
    expect(historyListLimit, 100);
    expect(historyKeepLimit, greaterThanOrEqualTo(historyListLimit));
  });

  test('Verse: referencia y ruta del enlace', () {
    const v = Verse(
      id: 1,
      bookId: 43,
      bookName: 'Juan',
      bookSlug: 'juan',
      chapter: 3,
      verse: 16,
      text: 'x',
    );
    expect(v.reference, 'Juan 3:16');
    expect(v.linkPath, 'juan-3-16');
  });

  test('VerseReference: igualdad, hash y toString', () {
    const a = VerseReference(43, 3, 16);
    expect(a, const VerseReference(43, 3, 16));
    expect(a.hashCode, const VerseReference(43, 3, 16).hashCode);
    expect(a, isNot(const VerseReference(43, 3, 17)));
    expect(a.toString(), contains('43'));
  });

  test(
    'FeedSelector: con todo visto reinicia en vez de dejar el feed vacío',
    () {
      final sel = FeedSelector(recentLimit: 500);
      final eligible = [for (var i = 1; i <= 5; i++) FeedCandidate(i, i)];
      final ids = sel.pick(
        eligible: eligible,
        recentIds: [for (var i = 1; i <= 5; i++) i],
        lastBooks: const [],
        count: 3,
      );
      expect(ids, isNotEmpty);
    },
  );
}
