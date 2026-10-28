import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/core/theme/card_style.dart';

/// Luminancia relativa WCAG 2.x (sRGB lineal), calculada aquí a propósito
/// para no depender de `Color.computeLuminance`.
double luminance(Color c) {
  double lin(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double contrast(Color a, Color b) {
  final la = luminance(a);
  final lb = luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('CardStyle (D8)', () {
    test('hay entre 8 y 10 estilos con id y nombre únicos', () {
      expect(CardStyle.all.length, inInclusiveRange(8, 10));
      expect(
        CardStyle.all.map((s) => s.id).toSet().length,
        CardStyle.all.length,
      );
      expect(
        CardStyle.all.map((s) => s.name).toSet().length,
        CardStyle.all.length,
      );
      expect(
        CardStyle.all.map((s) => s.name),
        containsAll(['Amanecer', 'Noche', 'Papel', 'Mar']),
      );
    });

    test('byId devuelve el estilo o null', () {
      expect(CardStyle.byId('mar')?.name, 'Mar');
      expect(CardStyle.byId('no-existe'), isNull);
    });

    test('la selección por verse_id es siempre la misma', () {
      for (final id in [19023001, 43003016, 66022021, 1001001]) {
        expect(CardStyle.forVerse(id), same(CardStyle.forVerse(id)));
      }
    });

    test('la selección reparte los estilos (no se queda en pocos)', () {
      final seen = <String>{};
      for (var i = 0; i < 400; i++) {
        seen.add(CardStyle.forVerse(19000000 + i * 1000 + 1).id);
      }
      expect(seen.length, CardStyle.all.length);
    });

    test('variante clara y oscura según el brillo', () {
      final s = CardStyle.all.first;
      expect(s.variant(Brightness.dark), same(s.dark));
      expect(s.variant(Brightness.light), same(s.light));
      expect(luminance(s.dark.top), lessThan(luminance(s.light.top)));
    });

    for (final style in CardStyle.all) {
      for (final (label, palette) in [
        ('clara', style.light),
        ('oscura', style.dark),
      ]) {
        test('${style.name} $label: texto 7:1 en todo el degradado', () {
          // Extremos, centro y puntos intermedios del degradado.
          for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
            final bg = Color.lerp(palette.top, palette.bottom, t)!;
            expect(
              contrast(palette.text, bg),
              greaterThanOrEqualTo(7.0),
              reason: 't=$t sobre ${bg.toARGB32().toRadixString(16)}',
            );
          }
        });

        test('${style.name} $label: acento 4.5:1 en todo el degradado', () {
          for (final t in [0.0, 0.5, 1.0]) {
            final bg = Color.lerp(palette.top, palette.bottom, t)!;
            expect(contrast(palette.accent, bg), greaterThanOrEqualTo(4.5));
          }
        });
      }
    }
  });
}
