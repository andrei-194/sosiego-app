/// Programación del versículo diario (HU-07.5/07.6). Dart puro (usa solo la
/// base de zonas horarias del paquete `timezone`).
library;

import 'package:timezone/timezone.dart' as tz;

/// Cuántas notificaciones se programan por adelantado (HU-07.5).
const scheduledNotificationCount = 30;

/// Zona horaria de respaldo (spec §10): Colombia, sin horario de verano.
const fallbackTimeZone = 'America/Bogota';

/// Largo máximo del texto del versículo en la notificación (HU-07.6).
const notificationTextLimit = 180;

/// Las tres horas de la tarjeta (HU-07.3), `HH:mm`.
const reminderPresetTimes = ['06:30', '13:00', '20:00'];

/// Una hora `HH:mm` válida o `null`.
({int hour, int minute})? parseTimeOfDay(String? value) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value?.trim() ?? '');
  if (m == null) return null;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return null;
  return (hour: h, minute: min);
}

String formatTimeOfDay(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Un día de la programación: instante en la zona de la persona y `MM-DD`
/// (clave de `daily_calendar`).
class PlannedDay {
  const PlannedDay(this.when, this.monthDay);
  final tz.TZDateTime when;
  final String monthDay;

  /// Fecha local (sin hora) para pedir el versículo del día.
  DateTime get localDate => DateTime(when.year, when.month, when.day);
}

String monthDayKey(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Las próximas [count] notificaciones, una por día a la hora [hour]:[minute]
/// de la zona de [now]. Si la hora de hoy ya pasó, empieza mañana. Funciona
/// desde cualquier hora y cruza meses, años y el 29 de febrero.
List<PlannedDay> planDailySchedule({
  required tz.TZDateTime now,
  required int hour,
  required int minute,
  int count = scheduledNotificationCount,
}) {
  final loc = now.location;
  var first = tz.TZDateTime(loc, now.year, now.month, now.day, hour, minute);
  if (!first.isAfter(now)) {
    first = tz.TZDateTime(loc, now.year, now.month, now.day + 1, hour, minute);
  }
  return [
    for (var i = 0; i < count; i++)
      () {
        final when = tz.TZDateTime(
          loc,
          first.year,
          first.month,
          first.day + i,
          hour,
          minute,
        );
        return PlannedDay(when, monthDayKey(when));
      }(),
  ];
}

/// Texto del versículo para la notificación: si pasa de 180 caracteres se
/// corta (el resultado tiene 180 como máximo) y termina en «…».
String truncateForNotification(
  String text, {
  int limit = notificationTextLimit,
}) {
  final runes = text.trim().runes.toList();
  if (runes.length <= limit) return text.trim();
  return '${String.fromCharCodes(runes.take(limit - 1)).trimRight()}…';
}

/// Zona de la persona sin plugin nativo: America/Bogota si el desfase del
/// teléfono coincide con el suyo; si no, la primera zona de la base con el
/// mismo desfase hoy y dentro de seis meses (así se evitan zonas con horario
/// de verano que no son la de la persona). Si ninguna coincide, Bogotá.
tz.Location resolveDeviceLocation({
  required Duration deviceOffset,
  required DateTime now,
}) {
  bool matches(tz.Location l, DateTime t) =>
      tz.TZDateTime.from(t, l).timeZoneOffset == deviceOffset;
  final later = now.add(const Duration(days: 182));
  final bogota = tz.getLocation(fallbackTimeZone);
  if (matches(bogota, now) && matches(bogota, later)) return bogota;
  tz.Location? loose;
  for (final loc in tz.timeZoneDatabase.locations.values) {
    if (!loc.name.contains('/') || loc.name.startsWith('Etc/')) continue;
    if (matches(loc, now)) {
      if (matches(loc, later)) return loc;
      loose ??= loc;
    }
  }
  return loose ?? bogota;
}
