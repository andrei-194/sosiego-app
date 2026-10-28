import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/streak.dart';

void main() {
  final today = DateTime(2026, 10, 28);

  test('sin actividad la racha es 0', () {
    expect(currentStreak({}, today), 0);
  });

  test('cuenta días seguidos incluyendo hoy', () {
    expect(currentStreak({'2026-10-28', '2026-10-27', '2026-10-26'}, today), 3);
  });

  test('si hoy aún no hay actividad, la racha de ayer sigue viva', () {
    expect(currentStreak({'2026-10-27', '2026-10-26'}, today), 2);
  });

  test('un hueco de un día rompe la racha', () {
    expect(currentStreak({'2026-10-26', '2026-10-25'}, today), 0);
  });

  test('cruza el cambio de mes y de año', () {
    expect(
      currentStreak({'2026-01-01', '2025-12-31'}, DateTime(2026, 1, 1)),
      2,
    );
  });
}
