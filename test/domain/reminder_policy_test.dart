import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/reminder_policy.dart';

void main() {
  final now = DateTime(2026, 10, 28, 9);

  bool show({
    bool enabled = false,
    int opens = 1,
    int seen = 0,
    int dismissCount = 0,
    DateTime? dismissedAt,
    DateTime? at,
  }) => shouldShowReminderCard(
    enabled: enabled,
    openCount: opens,
    versesSeen: seen,
    dismissCount: dismissCount,
    dismissedAt: dismissedAt,
    now: at ?? now,
  );

  group('HU-07 tarjeta del versículo diario', () {
    test('HU-07.3 no aparece en la primera apertura sin versículos vistos', () {
      expect(show(opens: 1, seen: 0), isFalse);
      expect(show(opens: 1, seen: 4), isFalse);
    });

    test('HU-07.3 aparece en la segunda apertura', () {
      expect(show(opens: 2), isTrue);
      expect(show(opens: 7), isTrue);
    });

    test(
      'HU-07.3 aparece tras ver 5 versículos aunque sea la primera apertura',
      () {
        expect(show(opens: 1, seen: 5), isTrue);
      },
    );

    test('HU-07.3 con el versículo diario activado no aparece', () {
      expect(show(enabled: true, opens: 5, seen: 9), isFalse);
    });

    test('HU-07.4 tras «Ahora no» no vuelve antes de 7 días', () {
      final d = DateTime(2026, 10, 21, 9);
      expect(
        show(
          opens: 4,
          dismissCount: 1,
          dismissedAt: d,
          at: d.add(const Duration(days: 6, hours: 23)),
        ),
        isFalse,
      );
    });

    test('HU-07.4 vuelve una sola vez a los 7 días', () {
      final d = DateTime(2026, 10, 21, 9);
      expect(
        show(
          opens: 4,
          dismissCount: 1,
          dismissedAt: d,
          at: d.add(const Duration(days: 7)),
        ),
        isTrue,
      );
    });

    test('HU-07.4 tras el segundo «Ahora no» solo se activa desde Ajustes', () {
      final d = DateTime(2026, 10, 1, 9);
      expect(
        show(
          opens: 40,
          seen: 100,
          dismissCount: 2,
          dismissedAt: d,
          at: d.add(const Duration(days: 365)),
        ),
        isFalse,
      );
    });
  });
}
