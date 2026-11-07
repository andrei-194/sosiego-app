import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/domain/text_normalizer.dart';

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
          normalizeSearchText(c['input'] as String),
          c['expected'] as String,
          reason: 'entrada: ${jsonEncode(c['input'])}',
        );
      });
    }
  });
}
