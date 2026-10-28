import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/font_scale.dart';
import 'package:sosiego/domain/streak.dart';
import 'package:sosiego/domain/verse_reference.dart';

void main() {
  final today = DateTime(2026, 10, 28);

  group('racha (HU-11)', () {
    test('HU-11.2 con 2 o más días seguidos muestra el contador', () {
      final s = streakStatus({'2026-10-28', '2026-10-27'}, today);
      expect(s.display, StreakDisplay.counting);
      expect(s.days, 2);
    });

    test('HU-11.5 con N = 1 no se muestra contador', () {
      expect(streakStatus({'2026-10-28'}, today).display, StreakDisplay.none);
    });

    test('HU-11.5 a quien nunca tuvo una racha no se le muestra nada', () {
      expect(streakStatus({}, today).display, StreakDisplay.none);
      expect(
        streakStatus({'2026-10-01', '2026-10-10'}, today).display,
        StreakDisplay.none,
      );
    });

    test(
      'HU-11.3 tras una racha de 2 o más interrumpida: buen día para empezar',
      () {
        final s = streakStatus({'2026-10-20', '2026-10-21'}, today);
        expect(s.display, StreakDisplay.restart);
      },
    );

    test('HU-11.4 el día 7 de la racha activa corresponde la tarjeta', () {
      final days = {
        for (var i = 0; i < 7; i++)
          '2026-10-${(28 - i).toString().padLeft(2, '0')}',
      };
      expect(streakStatus(days, today).milestone, isTrue);
      expect(
        streakStatus({...days}..remove('2026-10-28'), today).milestone,
        isFalse,
      );
    });
  });

  group('letra (HU-01)', () {
    test('HU-01.3 la preselección sale de la letra del sistema', () {
      expect(FontSizeChoice.forSystemScale(1.0), FontSizeChoice.normal);
      expect(FontSizeChoice.forSystemScale(1.29), FontSizeChoice.normal);
      expect(FontSizeChoice.forSystemScale(1.3), FontSizeChoice.grande);
      expect(FontSizeChoice.forSystemScale(1.59), FontSizeChoice.grande);
      expect(FontSizeChoice.forSystemScale(1.6), FontSizeChoice.muyGrande);
      expect(FontSizeChoice.forSystemScale(2.0), FontSizeChoice.muyGrande);
    });

    test('font_scale se guarda como normal, grande o muy_grande', () {
      expect(FontSizeChoice.values.map((c) => c.key), [
        'normal',
        'grande',
        'muy_grande',
      ]);
      expect(FontSizeChoice.fromKey('muy_grande'), FontSizeChoice.muyGrande);
      expect(FontSizeChoice.nearest(1.35), FontSizeChoice.grande);
    });
  });

  group('referencias (HU-06.3)', () {
    test('rango con guion', () {
      final r = parseReference('1 corintios 13:4-7')!;
      expect(r, const VerseReference(46, 13, 4, 7));
      expect(r.isRange, isTrue);
    });

    test('versículo separado solo por espacios', () {
      expect(parseReference('jn 3 16'), const VerseReference(43, 3, 16));
    });

    test('espacios de más y mayúsculas', () {
      expect(
        parseReference('  JUAN  3 : 16 '),
        const VerseReference(43, 3, 16),
      );
    });

    test('abreviatura numerada sin espacio', () {
      expect(parseReference('1co 13'), const VerseReference(46, 13));
      expect(parseReference('salmo 23'), const VerseReference(19, 23));
    });

    test('libro inexistente, capítulo fuera de rango y rango al revés', () {
      expect(parseReference('Marte 3:16'), isNull);
      expect(parseReference('salmo 151'), isNull);
      expect(parseReference('juan 22'), isNull);
      expect(parseReference('juan 3:16-10'), isNull);
    });
  });
}
