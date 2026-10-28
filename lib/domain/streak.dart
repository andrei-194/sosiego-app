import 'user_data.dart';

/// Días con actividad como `yyyy-MM-dd` (hora local). Racha = días seguidos
/// que terminan hoy o ayer (si hoy aún no se abrió la app, no se pierde).
int currentStreak(Set<String> activeDays, DateTime today) {
  var cursor = DateTime(today.year, today.month, today.day);
  if (!activeDays.contains(dayKey(cursor))) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  var count = 0;
  while (activeDays.contains(dayKey(cursor))) {
    count++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return count;
}

/// Qué muestra Inicio sobre la racha (spec HU-11.2, 11.3 y 11.5).
enum StreakDisplay {
  /// Nada: racha de 0 o 1 días, o quien nunca tuvo una racha de 2 o más.
  none,

  /// «Llevas N días contigo» (N de 2 o más).
  counting,

  /// «Hoy es un buen día para empezar»: hubo una racha de 2 o más que se
  /// interrumpió. Sin rojo, sin pérdida.
  restart,
}

/// Días en que aparece la tarjeta «N días con la Palabra» (HU-11.4).
const streakMilestones = [7, 30, 100];

class StreakStatus {
  const StreakStatus(this.display, this.days, {this.milestone = false});

  final StreakDisplay display;

  /// Días seguidos que terminan hoy o ayer.
  final int days;

  /// Hoy se cumple el día 7, 30 o 100: corresponde la tarjeta compartible.
  final bool milestone;

  static const none = StreakStatus(StreakDisplay.none, 0);
}

/// Calcula qué mostrar a partir de los días activos.
StreakStatus streakStatus(Set<String> activeDays, DateTime today) {
  final n = currentStreak(activeDays, today);
  if (n >= 2) {
    final todayActive = activeDays.contains(dayKey(today));
    return StreakStatus(
      StreakDisplay.counting,
      n,
      milestone: todayActive && streakMilestones.contains(n),
    );
  }
  if (n == 0 && _hadRun(activeDays, 2)) {
    return const StreakStatus(StreakDisplay.restart, 0);
  }
  return StreakStatus(StreakDisplay.none, n);
}

/// ¿Hubo alguna vez [length] o más días activos seguidos?
bool _hadRun(Set<String> activeDays, int length) {
  final days = activeDays.map(DateTime.parse).toList()..sort();
  var run = 0;
  DateTime? prev;
  for (final d in days) {
    final isNext =
        prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d;
    run = isNext ? run + 1 : 1;
    if (run >= length) return true;
    prev = d;
  }
  return false;
}
