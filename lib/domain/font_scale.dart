import 'dart:math' as math;

/// Tamaños de letra elegibles (spec HU-01 y §8).
enum FontSizeChoice {
  normal('normal', 1.0),
  grande('grande', 1.3),
  muyGrande('muy_grande', 1.6);

  const FontSizeChoice(this.key, this.factor);

  /// Valor que se guarda en `font_scale` (spec §6).
  final String key;

  /// Multiplicador de los tamaños base.
  final double factor;

  static FontSizeChoice? fromKey(String? key) {
    for (final c in values) {
      if (c.key == key) return c;
    }
    return null;
  }

  /// El tamaño elegible más cercano a un factor (para ajustes antiguos).
  static FontSizeChoice nearest(double factor) {
    var best = normal;
    for (final c in values) {
      if ((c.factor - factor).abs() < (best.factor - factor).abs()) best = c;
    }
    return best;
  }

  /// Preselección del primer arranque según la letra del sistema (HU-01.3):
  /// 1.3 o más es Grande y 1.6 o más es Muy grande.
  static FontSizeChoice forSystemScale(double systemScale) {
    if (systemScale >= 1.6) return muyGrande;
    if (systemScale >= 1.3) return grande;
    return normal;
  }
}

/// Factores elegibles, en el orden de [FontSizeChoice].
final List<double> fontChoices = [
  for (final c in FontSizeChoice.values) c.factor,
];

/// Tope absoluto del factor de escala (spec §8).
const double maxFontFactor = 2.0;

/// Factor efectivo = el mayor entre lo elegido en la app y la escala del
/// sistema, con tope 2.0. Nunca se achica lo que el usuario ya agrandó.
double effectiveFontFactor({required double chosen, required double system}) =>
    math.min(math.max(chosen, system), maxFontFactor);
