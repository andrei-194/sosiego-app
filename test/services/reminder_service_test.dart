import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosiego/data/services/notification_service.dart';
import 'package:sosiego/data/services/reminder_service.dart';
import 'package:sosiego/data/user/memory_user_repositories.dart';
import 'package:sosiego/data/user/providers.dart';
import 'package:sosiego/domain/reminder_policy.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/service_fakes.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('HU-07 programar el versículo diario', () {
    test(
      'HU-07.5 programa 30 con el texto de cada día y modo por el servicio',
      () async {
        final service = FakeNotificationService();
        final source = FakeDailySource();
        final n = await scheduleDailyNotifications(
          service: service,
          source: source,
          now: DateTime.utc(2026, 10, 28, 15),
          time: '06:30',
          title: 'Tu versículo de hoy',
        );
        expect(n, 30);
        expect(service.scheduled.length, 30);
        expect(service.scheduled.map((e) => e.id).toSet().length, 30);
        expect(
          service.scheduled.first.body,
          contains('Texto del 10-29'.replaceAll('10-29', '10-29')),
        );
        expect(service.scheduled[1].body, contains('Texto del 10-30'));
        expect(service.scheduled.first.payload, '/hoy');
        expect(service.scheduled.first.when.hour, 6);
      },
    );

    test(
      'HU-07.6 el versículo de más de 180 caracteres se corta con …',
      () async {
        final service = FakeNotificationService();
        await scheduleDailyNotifications(
          service: service,
          source: FakeDailySource(textFor: (_) => 'palabra ' * 60),
          now: DateTime.utc(2026, 10, 28, 15),
          time: '20:00',
          title: 't',
          count: 2,
        );
        final body = service.scheduled.first.body;
        final text = body.split('\n').first;
        // «» + 180 como máximo.
        expect(text.length, lessThanOrEqualTo(182));
        expect(text.endsWith('…»'), isTrue);
        expect(body.split('\n').last, 'Juan 3:16');
      },
    );

    test('HU-07.1 el 29 de febrero pide el versículo de esa fecha', () async {
      final service = FakeNotificationService();
      final source = FakeDailySource();
      await scheduleDailyNotifications(
        service: service,
        source: source,
        now: tz.TZDateTime(service.location, 2028, 2, 27, 14),
        time: '13:00',
        title: 't',
      );
      expect(source.asked, contains(DateTime(2028, 2, 29)));
    });
  });

  group('HU-07 tarjeta y permiso', () {
    late FakeNotificationService service;
    late MemoryAppStateRepository appState;
    late MemoryHistoryRepository history;
    late DateTime clock;

    ProviderContainer container() => ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(service),
        dailyVerseSourceProvider.overrideWithValue(FakeDailySource()),
        appStateRepositoryProvider.overrideWith((_) => appState),
        historyRepositoryProvider.overrideWith((_) => history),
        clockProvider.overrideWithValue(() => clock),
      ],
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = FakeNotificationService();
      appState = MemoryAppStateRepository();
      history = MemoryHistoryRepository();
      clock = DateTime(2026, 10, 28, 9);
    });

    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('HU-07.3 la tarjeta no pide permiso al aparecer', () async {
      await appState.set(ReminderStateKeys.openCount, '2');
      final c = container();
      addTearDown(c.dispose);
      c.read(reminderCardProvider);
      await settle();
      expect(c.read(reminderCardProvider).phase, ReminderCardPhase.ask);
      expect(service.permissionRequests, 0);
    });

    test('HU-07.3 aparece tras ver 5 versículos (historial)', () async {
      for (var i = 0; i < 5; i++) {
        await history.record(19023001 + i);
      }
      final c = container();
      addTearDown(c.dispose);
      c.read(reminderCardProvider);
      await settle();
      expect(c.read(reminderCardProvider).phase, ReminderCardPhase.ask);
    });

    test(
      'HU-07.3 solo al tocar una hora se pide el permiso y se programa',
      () async {
        await appState.set(ReminderStateKeys.openCount, '3');
        final c = container();
        addTearDown(c.dispose);
        c.read(reminderCardProvider);
        await settle();
        await c.read(reminderCardProvider.notifier).choose('13:00');
        expect(service.permissionRequests, 1);
        expect(c.read(reminderCardProvider).phase, ReminderCardPhase.done);
        expect(c.read(reminderControllerProvider).enabled, isTrue);
        expect(c.read(reminderControllerProvider).time, '13:00');
        expect(service.scheduled.length, 30);
        expect(service.scheduled.first.when.hour, 13);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(notifEnabledKey), isTrue);
        expect(prefs.getString(notifTimeKey), '13:00');
      },
    );

    test('HU-07.3 si se niega el permiso: mensaje amable, nada programado, no insiste', () async {
      service.grant = false;
      await appState.set(ReminderStateKeys.openCount, '3');
      final c = container();
      addTearDown(c.dispose);
      c.read(reminderCardProvider);
      await settle();
      await c.read(reminderCardProvider.notifier).choose('06:30');
      expect(c.read(reminderCardProvider).phase, ReminderCardPhase.denied);
      expect(c.read(reminderControllerProvider).enabled, isFalse);
      expect(service.scheduled, isEmpty);
      expect(await appState.get(ReminderStateKeys.dismissCount), '2');
    });

    test(
      'HU-07.4 «Ahora no» oculta y vuelve una sola vez a los 7 días',
      () async {
        await appState.set(ReminderStateKeys.openCount, '2');
        final c = container();
        addTearDown(c.dispose);
        c.read(reminderCardProvider);
        await settle();
        await c.read(reminderCardProvider.notifier).dismiss();
        expect(c.read(reminderCardProvider).phase, ReminderCardPhase.hidden);
        expect(await appState.get(ReminderStateKeys.dismissCount), '1');

        // Seis días después sigue oculta.
        clock = clock.add(const Duration(days: 6));
        final c2 = container();
        addTearDown(c2.dispose);
        c2.read(reminderCardProvider);
        await settle();
        expect(c2.read(reminderCardProvider).phase, ReminderCardPhase.hidden);

        // A los 7 días vuelve.
        clock = DateTime(2026, 10, 28, 9).add(const Duration(days: 7));
        final c3 = container();
        addTearDown(c3.dispose);
        c3.read(reminderCardProvider);
        await settle();
        expect(c3.read(reminderCardProvider).phase, ReminderCardPhase.ask);
        await c3.read(reminderCardProvider.notifier).dismiss();

        // Y después ya no vuelve.
        clock = clock.add(const Duration(days: 90));
        final c4 = container();
        addTearDown(c4.dispose);
        c4.read(reminderCardProvider);
        await settle();
        expect(c4.read(reminderCardProvider).phase, ReminderCardPhase.hidden);
      },
    );

    test('HU-07.5 al cambiar la hora se reprograma las 30', () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(reminderControllerProvider.notifier).enable('06:30');
      expect(service.scheduled.first.when.hour, 6);
      await c.read(reminderControllerProvider.notifier).setTime('20:00');
      expect(service.scheduled.length, 30);
      expect(service.scheduled.first.when.hour, 20);
      await c.read(reminderControllerProvider.notifier).disable();
      expect(service.scheduled, isEmpty);
      expect(c.read(reminderControllerProvider).enabled, isFalse);
    });

    test('HU-07.5 reprogramar sin activar no programa nada', () async {
      final c = container();
      addTearDown(c.dispose);
      await c.read(reminderControllerProvider.notifier).reschedule();
      expect(service.scheduled, isEmpty);
    });
  });
}
