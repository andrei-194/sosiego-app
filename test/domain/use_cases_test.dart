import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/data/content/use_case_impls.dart';
import 'package:sosiego/domain/content_models.dart';
import 'package:sosiego/domain/favorites_export.dart';
import 'package:sosiego/domain/feed_mode.dart';
import 'package:sosiego/domain/feed_selector.dart';
import 'package:sosiego/domain/use_cases.dart';

void main() {
  late ContentRepository repo;
  setUpAll(() => repo = ContentRepository('assets/db/content.db'));
  tearDownAll(() => repo.close());

  group('GetNextVerse (spec 4)', () {
    GetNextVerseImpl make(int seed) =>
        GetNextVerseImpl(repo, selector: FeedSelector(random: Random(seed)));

    test(
      'HU-04.3 no muestra más de dos versículos seguidos del mismo libro',
      () {
        for (var seed = 0; seed < 20; seed++) {
          final verses = make(seed)(
            const FeedRequest(mode: FeedMode.general, count: 21),
          );
          for (var i = 2; i < verses.length; i++) {
            final run = {
              verses[i].bookId,
              verses[i - 1].bookId,
              verses[i - 2].bookId,
            };
            expect(run.length, greaterThan(1), reason: 'semilla $seed pos $i');
          }
        }
      },
    );

    test('HU-04.3 respeta la tanda anterior al rellenar la cola', () {
      final uc = make(3);
      final first = uc(const FeedRequest(mode: FeedMode.general, count: 21));
      final more = uc(
        FeedRequest(
          mode: FeedMode.general,
          count: 20,
          shownIds: first.map((v) => v.id).toList(),
        ),
      );
      final all = [...first, ...more];
      expect(all.map((v) => v.id).toSet().length, all.length);
      for (var i = 2; i < all.length; i++) {
        expect(
          {all[i].bookId, all[i - 1].bookId, all[i - 2].bookId}.length,
          greaterThan(1),
        );
      }
    });

    test('seccion 4.3 no repite los últimos vistos y solo usa elegibles', () {
      final eligible = repo.eligibleCandidates();
      final recent = eligible.take(60).map((c) => c.id).toList();
      final verses = make(5)(
        FeedRequest(mode: FeedMode.general, count: 21, recentIds: recent),
      );
      final ids = eligible.map((c) => c.id).toSet();
      expect(verses.every((v) => ids.contains(v.id)), isTrue);
      expect(verses.any((v) => recent.contains(v.id)), isFalse);
    });

    test('HU-05.1 parecidos: los 10 de verse_similar en orden de rank', () {
      final verses = make(1)(
        const FeedRequest(mode: FeedMode.similar(43003016), count: 21),
      );
      expect(verses.map((v) => v.id), repo.similarIds(43003016));
      expect(verses, hasLength(10));
    });

    test('seccion 4.4 momento: sale de moment_verses por rank', () {
      final moment = repo.moments().first;
      final verses = make(1)(
        FeedRequest(mode: FeedMode.moment(moment.slug), count: 21),
      );
      expect(verses.map((v) => v.id), repo.momentVerseIds(moment.id));
    });

    test('seccion 4.4 tema: solo versículos con peso de 0.6 o más', () {
      final theme = repo.themeBySlug('ansiedad')!;
      final allowed = repo.themeCandidates(theme.id).map((c) => c.id).toSet();
      final verses = make(2)(
        const FeedRequest(mode: FeedMode.theme('ansiedad'), count: 21),
      );
      expect(verses, isNotEmpty);
      expect(verses.every((v) => allowed.contains(v.id)), isTrue);
    });
  });

  group('SearchVerses (HU-06)', () {
    SearchVersesImpl make() => SearchVersesImpl(repo);

    test('HU-06.3 una referencia devuelve ese versículo', () {
      final o = make()('Juan 3:16');
      expect(o.referenceVerses.map((v) => v.id), [43003016]);
    });

    test('HU-06.3 un rango devuelve los versículos en orden', () {
      final o = make()('filipenses 4:6-8');
      expect(o.referenceVerses.map((v) => v.verse), [6, 7, 8]);
    });

    test('HU-06.3 un capítulo devuelve la lista de sus versículos', () {
      final o = make()('salmo 23');
      expect(o.referenceVerses.map((v) => v.verse), [1, 4]);
    });

    test('HU-06.4 una emoción activa el atajo a tema', () {
      final o = make()('Ansiedad');
      expect(o.topic?.slug, 'ansiedad');
      expect(o.topic?.isMoment, isFalse);
    });

    test('HU-06.4 un momento activa el atajo a tema', () {
      final o = make()('antes de dormir');
      expect(o.topic?.isMoment, isTrue);
    });

    test('HU-06.5 texto con prefijo en la última palabra, sin tildes', () {
      final o = make()('confia');
      expect(o.textMatches, isNotEmpty);
      expect(o.textMatches.length, lessThanOrEqualTo(30));
      expect(make()('descanso conf').textMatches, isNotEmpty);
    });

    test('HU-06.5 máximo 30 resultados', () {
      expect(make()('muestra').textMatches.length, 30);
    });

    test('HU-06.7 sin coincidencias devuelve un resultado vacío', () {
      expect(make()('zzzzqqq').isEmpty, isTrue);
    });

    test('HU-13.1 términos de crisis activan el bloque de ayuda', () {
      expect(make()('quiero morir').crisis, isTrue);
      expect(make()('paz').crisis, isFalse);
    });
  });

  group('GetDailyContent (HU-07.1)', () {
    test('HU-07.1 incluye el 29 de febrero', () {
      final d = GetDailyContentImpl(repo)(DateTime(2028, 2, 29));
      expect(d, isNotNull);
      expect(d!.verse.id, repo.dailyVerseFor(DateTime(2028, 2, 29))!.id);
    });

    test('HU-07.1 mismo día de otro año, mismo versículo', () {
      expect(
        repo.dailyVerseFor(DateTime(2026, 10, 28))!.id,
        repo.dailyVerseFor(DateTime(2027, 10, 28))!.id,
      );
    });
  });

  group('Acompañamiento (HU-03)', () {
    Reflection r(int id, int verseId) => Reflection(
      id: id,
      verseId: verseId,
      kind: ReflectionKind.emotion,
      contextText: 'c',
      reflectionText: 'r',
      applicationText: 'a',
      prayerText: 'p',
      readingSeconds: 47,
    );

    test('HU-03.1 evita las reflexiones de versículos vistos', () {
      final picked = pickReflection(
        [r(1, 10), r(2, 20)],
        recentVerseIds: [10],
        nextInt: (_) => 0,
      );
      expect(picked!.id, 2);
    });

    test('HU-03.1 si todas se vieron, elige cualquiera del tema', () {
      final picked = pickReflection(
        [r(1, 10), r(2, 20)],
        recentVerseIds: [10, 20],
        nextInt: (_) => 0,
      );
      expect(picked, isNotNull);
    });

    test('HU-03.4 «Otra palabra» no repite la actual', () {
      final picked = pickReflection(
        [r(1, 10), r(2, 20)],
        recentVerseIds: const [],
        excludeId: 1,
        nextInt: (_) => 0,
      );
      expect(picked!.id, 2);
    });

    test('HU-03.3 el tiempo de lectura sale de reading_seconds', () {
      expect(r(1, 1).readingMinutes, 1);
      const longer = Reflection(
        id: 9,
        verseId: 1,
        kind: ReflectionKind.daily,
        contextText: '',
        reflectionText: '',
        applicationText: '',
        prayerText: '',
        readingSeconds: 100,
      );
      expect(longer.readingMinutes, 2);
    });

    test('HU-03.1 el repositorio devuelve reflexiones de la emoción', () {
      final c = GetCompanionImpl(repo, random: Random(1));
      final x = c.forEmotion('tristeza');
      expect(x, isNotNull);
      expect(x!.kind, ReflectionKind.emotion);
      expect(c.forEmotion('tristeza', excludeId: x.id)!.id, isNot(x.id));
    });
  });

  test('HU-10.6 «Enviarme mis guardados» lleva referencia y versículo', () {
    final t = buildFavoritesExport(
      header: 'Mis guardados',
      footer: 'Sosiego',
      items: [(reference: 'Juan 3:16', text: 'Porque de tal manera')],
    );
    expect(t, contains('Juan 3:16\n«Porque de tal manera»'));
    expect(t.startsWith('Mis guardados'), isTrue);
  });
}
