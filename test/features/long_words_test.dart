import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/domain/text_normalizer.dart';

import '../golden/golden_helpers.dart';
import '../helpers/pump_app.dart';

/// Palabras largas con letra muy grande: ninguna se parte a mitad de palabra.
/// Una palabra en una sola línea mide lo mismo que otra corta del mismo estilo.
/// Se cargan las fuentes reales: con la de pruebas cada letra es un cuadrado.
void main() {
  group('palabras largas con letra al 200 %', () {
    for (final width in [360.0, 320.0]) {
      appTest(
        '«Guardados» en la barra inferior queda en una línea ($width dp)',
        (tester) async {
          await tester.runAsync(loadGoldenFonts);
          await pumpApp(tester, scale: 2.0);
          tester.view.physicalSize = Size(width * 3, 2160);
          await tester.pumpAndSettle();
          Size label(String t) => tester.getSize(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(t),
            ),
          );
          expect(label('Guardados').height, label('Inicio').height);
          expect(tester.takeException(), isNull);
        },
      );

      appTest('el título «Guardados» y las pestañas no se parten ($width dp)', (
        tester,
      ) async {
        await tester.runAsync(loadGoldenFonts);
        await pumpApp(tester, scale: 2.0);
        tester.view.physicalSize = Size(width * 3, 2160);
        await tester.pumpAndSettle();
        await tapTab(tester, 'Guardados');

        // Título: 32 sp acotado a 1.5 (una línea ≈ 58 dp; dos serían > 100).
        final title = find.text('Guardados').first;
        expect(tester.getSize(title).height, lessThan(80));

        // Pestañas Guardados | Vistos: mismo alto = ambas en una línea.
        Size tab(String t) => tester.getSize(
          find.descendant(
            of: find.byKey(const Key('favorites-tabs')),
            matching: find.text(t),
          ),
        );
        expect(tab('Guardados').height, tab('Vistos').height);
        expect(tester.takeException(), isNull);
      });
    }

    appTest('el selector de Guardados usa la fuente de la app', (tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'Guardados');
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('favorites-tabs')),
          matching: find.text('Vistos'),
        ),
      );
      final style = DefaultTextStyle.of(
        tester.element(
          find.descendant(
            of: find.byKey(const Key('favorites-tabs')),
            matching: find.text('Vistos'),
          ),
        ),
      ).style;
      expect(text.data, 'Vistos');
      expect(style.fontFamily, contains('AtkinsonHyperlegible'));
    });
  });

  group('una sola normalización de búsqueda', () {
    test('queryTokens parte lo que normalizeSearchText deja normalizado', () {
      for (final q in [
        '  Ánimo,   ¡fortaleza! ',
        'Juan 3:16',
        '«El Señor»',
        '',
        '---',
      ]) {
        final norm = normalizeSearchText(q);
        expect(
          ContentRepository.queryTokens(q),
          norm.isEmpty ? isEmpty : norm.split(' '),
          reason: q,
        );
      }
    });

    test('normalizeSearchText quita tildes, signos y espacios sobrantes', () {
      expect(
        normalizeSearchText('  ¿Dónde está el Señor? '),
        'donde esta el senor',
      );
    });
  });
}
