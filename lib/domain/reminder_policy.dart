/// Cuándo se muestra la tarjeta «¿Quieres recibir el versículo cada día?»
/// (HU-07.3 y HU-07.4). Dart puro: el reloj llega por parámetro.
library;

/// Claves de `app_state` que usa el recordatorio.
class ReminderStateKeys {
  /// Veces que se abrió la app (se suma una por arranque).
  static const openCount = 'open_count';

  /// Cuándo respondió «Ahora no» por última vez (epoch en milisegundos).
  static const dismissedAt = 'reminder_dismissed_at';

  /// Cuántas veces respondió «Ahora no» (o negó el permiso).
  static const dismissCount = 'reminder_dismiss_count';
}

/// Cuánto espera la tarjeta antes de volver una sola vez (HU-07.4).
const reminderComeBackAfter = Duration(days: 7);

/// Versículos vistos a partir de los cuales aparece la tarjeta (HU-07.3).
const reminderVersesThreshold = 5;

/// Aperturas a partir de las cuales aparece la tarjeta (HU-07.3).
const reminderOpensThreshold = 2;

/// Decide si se muestra la tarjeta.
///
/// - Con el versículo diario activado no se muestra.
/// - Aparece en la segunda apertura o tras ver 5 versículos, lo que ocurra
///   primero.
/// - Con «Ahora no» vuelve UNA sola vez, a los 7 días; después, solo desde
///   Ajustes.
bool shouldShowReminderCard({
  required bool enabled,
  required int openCount,
  required int versesSeen,
  required int dismissCount,
  required DateTime? dismissedAt,
  required DateTime now,
}) {
  if (enabled) return false;
  final triggered =
      openCount >= reminderOpensThreshold ||
      versesSeen >= reminderVersesThreshold;
  if (!triggered) return false;
  if (dismissCount <= 0) return true;
  if (dismissCount == 1 && dismissedAt != null) {
    return !now.isBefore(dismissedAt.add(reminderComeBackAfter));
  }
  return false;
}
