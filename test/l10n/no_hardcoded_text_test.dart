import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Spec §7 «Idioma»: todos los textos van en ARB. Esta prueba falla si aparece
/// un literal de texto fijo en un widget: `Text('…')` o un argumento visible
/// (`tooltip`, `label`, `hintText`, `title`…) con un literal que lleve letras.
///
/// Los literales sin letras (comillas decorativas, números, separadores) y los
/// archivos de datos de muestra de la lista de excepciones quedan fuera.

/// Archivos exentos, con la razón. Son contenido (lo que irá en content.db),
/// no interfaz: nombres de temas y momentos, reflexiones de ejemplo.
const exceptions = <String, String>{
  'lib/features/explore/mock_data.dart':
      'Muestra de themes/moments de content.db (name_es, description)',
  'lib/features/reflection/mock_data.dart':
      'Muestra de reflections de content.db (contenido, no interfaz)',
};

/// Carpetas y archivos que se revisan.
const scanned = [
  'lib/features',
  'lib/core',
  'lib/app.dart',
  'lib/app_router.dart',
];

final _letter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');

final _patterns = <RegExp>[
  // Text('…'), const Text("…"), Text.rich no (se arma con TextSpan).
  RegExp(r'''\bText\(\s*r?(['"])((?:(?!\1).)*)\1'''),
  // Argumentos que muestran texto o lo leen TalkBack.
  RegExp(
    r'''\b(tooltip|label|labelText|hintText|helperText|semanticLabel|semanticsLabel|title|subtitle|message|actionLabel|text)\s*:\s*(?:const\s+)?r?(['"])((?:(?!\2).)*)\2''',
  ),
];

/// Devuelve los literales con letras que aparecen como texto fijo en [source].
List<String> findHardcodedTexts(String source) {
  final found = <String>[];
  // Sin comentarios de línea, para no confundir «// Text('...')».
  final code = source
      .split('\n')
      .map((l) => l.replaceFirst(RegExp(r'^\s*//.*$'), ''))
      .join('\n');
  for (final p in _patterns) {
    for (final m in p.allMatches(code)) {
      final literal = m.group(m.groupCount)!;
      // Se ignoran las interpolaciones: '$a. $b' solo une datos con puntuación.
      final fixed = literal
          .replaceAll(RegExp(r'\$\{[^}]*\}'), '')
          .replaceAll(RegExp(r'\$\w+'), '');
      if (_letter.hasMatch(fixed)) found.add(m.group(0)!);
    }
  }
  return found;
}

void main() {
  group('sin textos fijos en widgets (spec §7)', () {
    test('el detector encuentra los literales típicos', () {
      expect(findHardcodedTexts("child: Text('Hola')"), isNotEmpty);
      expect(findHardcodedTexts('child: const Text("Hola mundo")'), isNotEmpty);
      expect(findHardcodedTexts("IconButton(tooltip: 'Volver')"), isNotEmpty);
      expect(findHardcodedTexts("label: const Text('x')"), isNotEmpty);
      expect(
        findHardcodedTexts("NavigationDestination(label: 'Inicio')"),
        isNotEmpty,
      );
      expect(
        findHardcodedTexts("InputDecoration(hintText: 'Buscar')"),
        isNotEmpty,
      );
      expect(findHardcodedTexts("Semantics(label: 'Paso 1')"), isNotEmpty);
    });

    test(
      'el detector deja pasar textos de l10n, interpolaciones y adornos',
      () {
        expect(findHardcodedTexts('Text(context.l10n.navHome)'), isEmpty);
        expect(findHardcodedTexts('Text(l.readingTime(3))'), isEmpty);
        expect(findHardcodedTexts("Text('“', style: s)"), isEmpty);
        expect(findHardcodedTexts("TextSpan(text: '12  ')"), isEmpty);
        expect(findHardcodedTexts("// Text('Comentario')"), isEmpty);
        expect(findHardcodedTexts("key: const Key('feed')"), isEmpty);
        expect(findHardcodedTexts(r"label: '$title. ${x.y}'"), isEmpty);
        expect(findHardcodedTexts(r"label: 'Paso $n'"), isNotEmpty);
      },
    );

    test('ningún archivo de lib/ tiene textos fijos', () {
      final offenders = <String>[];
      for (final path in scanned) {
        final type = FileSystemEntity.typeSync(path);
        final files = type == FileSystemEntityType.directory
            ? Directory(path)
                  .listSync(recursive: true)
                  .whereType<File>()
                  .where((f) => f.path.endsWith('.dart'))
            : [File(path)];
        for (final f in files) {
          final rel = f.path.replaceAll('\\', '/');
          if (exceptions.containsKey(rel)) continue;
          for (final hit in findHardcodedTexts(f.readAsStringSync())) {
            offenders.add('$rel: ${hit.replaceAll('\n', ' ')}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'Mueve estos textos a lib/l10n/app_es.arb y usa context.l10n:\n'
            '${offenders.join('\n')}',
      );
    });

    test('las excepciones existen (no quedan entradas muertas)', () {
      for (final path in exceptions.keys) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });
  });
}
