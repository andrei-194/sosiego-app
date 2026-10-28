import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/text_normalizer.dart';

void main() {
  test('quita tildes, diéresis y ñ', () {
    expect(normalizeText('Corazón'), 'corazon');
    expect(normalizeText('Pingüino'), 'pinguino');
    expect(normalizeText('Año'), 'ano');
  });

  test('pasa a minúsculas y conserva el resto', () {
    expect(normalizeText('PAZ, y descanso 23:1'), 'paz, y descanso 23:1');
  });

  test('es idempotente', () {
    const s = 'Él confía en Jehová';
    expect(normalizeText(normalizeText(s)), normalizeText(s));
  });
}
