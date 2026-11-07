import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/text_normalizer.dart';

/// Normalización completa de búsqueda tal como la usa la app
/// (`SearchVersesImpl._norm` y `ContentRepository.queryTokens`): `normalizeText`
/// quita tildes y pasa a minúsculas; lo que no es letra o número pasa a espacio.
String _fullNormalize(String s) =>
    normalizeText(s).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

void main() {
  final file = File('tools/shared/normalize_cases.json');
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final cases = (data['cases'] as List).cast<Map<String, dynamic>>();

  group('normalización compartida con el pipeline (spec 10, datos 9)', () {
    test('el archivo de casos tiene contenido', () {
      expect(cases.length, greaterThanOrEqualTo(20));
    });

    for (final c in cases) {
      test('HU-06.8 caso ${c['id']}', () {
        expect(
          _fullNormalize(c['input'] as String),
          c['expected'] as String,
          reason: 'entrada: ${jsonEncode(c['input'])}',
        );
      });
    }
  });
}
