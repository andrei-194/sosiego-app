import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/font_scale.dart';

void main() {
  test('usa el mayor entre la elección y el sistema', () {
    expect(effectiveFontFactor(chosen: 1.0, system: 1.3), 1.3);
    expect(effectiveFontFactor(chosen: 1.6, system: 1.0), 1.6);
  });

  test('nunca pasa de 2.0', () {
    expect(effectiveFontFactor(chosen: 1.6, system: 3.0), 2.0);
  });

  test('las opciones son 1.0, 1.3 y 1.6', () {
    expect(fontChoices, [1.0, 1.3, 1.6]);
  });
}
