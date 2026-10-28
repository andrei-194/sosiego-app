import 'dart:math' as math;

/// Tamaños de letra elegibles en Ajustes.
const List<double> fontChoices = [1.0, 1.3, 1.6];

/// Tope absoluto del factor de escala (spec §8).
const double maxFontFactor = 2.0;

/// Factor efectivo = el mayor entre lo elegido en la app y la escala del
/// sistema, con tope 2.0. Nunca se achica lo que el usuario ya agrandó.
double effectiveFontFactor({required double chosen, required double system}) =>
    math.min(math.max(chosen, system), maxFontFactor);
