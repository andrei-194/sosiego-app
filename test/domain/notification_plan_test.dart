import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/notification_plan.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

DateTime _day(tz.TZDateTime t) => DateTime.utc(t.year, t.month, t.day);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('HU-07 programación', () {
    test(
      'HU-07.5 programa 30 notificaciones, una por día, desde cualquier hora',
      () {
        final bogota = tz.getLocation('America/Bogota');
        for (var hour = 0; hour < 24; hour++) {
          for (final minute in [0, 29, 30, 59]) {
            final now = tz.TZDateTime(bogota, 2026, 10, 28, hour, minute);
            final plan = planDailySchedule(now: now, hour: 6, minute: 30);
            expect(plan.length, 30, reason: '$hour:$minute');
            for (var i = 0; i < plan.length; i++) {
              expect(plan[i].when.isAfter(now), isTrue);
              expect(plan[i].when.hour, 6);
              expect(plan[i].when.minute, 30);
              if (i > 0) {
                expect(
                  _day(plan[i.toInt()].when)
                      .difference(_day(plan[i - 1].when))
                      .inDays,
                  1,
                );
              }
            }
            final todaySlot = tz.TZDateTime(bogota, 2026, 10, 28, 6, 30);
            expect(plan.first.when.day, todaySlot.isAfter(now) ? 28 : 29);
          }
        }
      },
    );

    test('HU-07.5 cruza fin de mes y de año', () {
      final bogota = tz.getLocation('America/Bogota');
      final plan = planDailySchedule(
        now: tz.TZDateTime(bogota, 2026, 12, 20, 22),
        hour: 20,
        minute: 0,
      );
      expect(plan.first.monthDay, '12-21');
      expect(plan.map((p) => p.monthDay), contains('12-31'));
      expect(plan.map((p) => p.monthDay), contains('01-01'));
      expect(plan.last.monthDay, '01-19');
    });

    test('HU-07.1 el 29 de febrero entra como 02-29 en año bisiesto', () {
      final bogota = tz.getLocation('America/Bogota');
      final plan = planDailySchedule(
        now: tz.TZDateTime(bogota, 2028, 2, 27, 14),
        hour: 13,
        minute: 0,
      );
      expect(plan.map((p) => p.monthDay).take(4), [
        '02-28',
        '02-29',
        '03-01',
        '03-02',
      ]);
      expect(plan[1].localDate, DateTime(2028, 2, 29));
      final comun = planDailySchedule(
        now: tz.TZDateTime(bogota, 2027, 2, 27, 10),
        hour: 13,
        minute: 0,
      );
      expect(comun.map((p) => p.monthDay), isNot(contains('02-29')));
      expect(comun.map((p) => p.monthDay).take(3), ['02-27', '02-28', '03-01']);
    });

    test('HU-07.1 cambio de zona: America/Bogota fija día y hora locales', () {
      final bogota = tz.getLocation('America/Bogota');
      final instante = DateTime.utc(2026, 10, 29, 3);
      final enBogota = planDailySchedule(
        now: tz.TZDateTime.from(instante, bogota),
        hour: 6,
        minute: 30,
      );
      expect(enBogota.first.monthDay, '10-29');
      expect(enBogota.first.when.timeZoneOffset, const Duration(hours: -5));
      expect(enBogota.first.when.toUtc(), DateTime.utc(2026, 10, 29, 11, 30));
      final enUtc = planDailySchedule(
        now: tz.TZDateTime.from(instante, tz.UTC),
        hour: 6,
        minute: 30,
      );
      expect(enUtc.first.when.toUtc(), DateTime.utc(2026, 10, 29, 6, 30));
      expect(enBogota.first.when.toUtc(), isNot(enUtc.first.when.toUtc()));
    });

    test('HU-07.1 resuelve America/Bogota con desfase -5 y otra zona si no coincide', () {
      final now = DateTime.utc(2026, 10, 28, 12);
      expect(
        resolveDeviceLocation(
          deviceOffset: const Duration(hours: -5),
          now: now,
        ).name,
        'America/Bogota',
      );
      final otra = resolveDeviceLocation(
        deviceOffset: const Duration(hours: 1),
        now: now,
      );
      expect(
        tz.TZDateTime.from(now, otra).timeZoneOffset,
        const Duration(hours: 1),
      );
      expect(fallbackTimeZone, 'America/Bogota');
    });

    test('HU-07.6 el texto largo se corta en 180 caracteres con «…»', () {
      final corto = 'a' * 180;
      expect(truncateForNotification(corto), corto);
      final cortado = truncateForNotification('palabra ' * 40);
      expect(cortado.length, lessThanOrEqualTo(notificationTextLimit));
      expect(cortado.endsWith('…'), isTrue);
      final justo = truncateForNotification('b' * 181);
      expect(justo.length, 180);
      expect(justo.endsWith('…'), isTrue);
    });

    test(
      'HU-07.3 las tres horas son 6:30, 13:00 y 20:00 y se leen como HH:mm',
      () {
        expect(reminderPresetTimes, ['06:30', '13:00', '20:00']);
        expect(parseTimeOfDay('06:30'), (hour: 6, minute: 30));
        expect(parseTimeOfDay('6:05'), (hour: 6, minute: 5));
        expect(parseTimeOfDay('24:00'), isNull);
        expect(parseTimeOfDay('12:60'), isNull);
        expect(parseTimeOfDay(null), isNull);
        expect(formatTimeOfDay(6, 5), '06:05');
      },
    );
  });
}
