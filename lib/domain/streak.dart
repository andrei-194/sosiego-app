/// Días con actividad como `yyyy-MM-dd` (hora local). Racha = días seguidos
/// que terminan hoy o ayer (si hoy aún no se abrió la app, no se pierde).
int currentStreak(Set<String> activeDays, DateTime today) {
  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  var cursor = DateTime(today.year, today.month, today.day);
  if (!activeDays.contains(fmt(cursor))) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  var count = 0;
  while (activeDays.contains(fmt(cursor))) {
    count++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return count;
}
