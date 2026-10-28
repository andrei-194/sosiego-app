import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/pump_app.dart';

void main() {
  group('navegación', () {
    testWidgets('la barra inferior lleva a cada pestaña y de vuelta al feed', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.byKey(const Key('feed')), findsOneWidget);

      await tapTab(tester, 'Explorar');
      expect(find.byKey(const Key('daily-card')), findsOneWidget);

      await tapTab(tester, 'Buscar');
      expect(find.byKey(const Key('search-field')), findsOneWidget);

      await tapTab(tester, 'Guardados');
      expect(find.byKey(const Key('favorites-empty')), findsOneWidget);

      await tapTab(tester, 'Inicio');
      expect(find.byKey(const Key('verse-text')), findsOneWidget);
    });

    testWidgets('el feed abre ajustes y se vuelve con Volver', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Tamaño de letra'), findsOneWidget);

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feed')), findsOneWidget);
    });

    testWidgets('del feed al detalle, reflexión y capítulo', (tester) async {
      // Fija el primer versículo: el de Salmos 23:1 tiene reflexión.
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Reflexión, capítulo y más como este'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open-chapter')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('open-chapter')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-chapter')));
      await tester.pumpAndSettle();
      expect(find.text('Reina-Valera 1909'), findsOneWidget);
    });

    testWidgets('buscar por referencia y por texto', (tester) async {
      await pumpApp(tester);
      await tapTab(tester, 'Buscar');

      await tester.enterText(find.byKey(const Key('search-field')), 'Sal 23:1');
      await tester.pumpAndSettle();
      expect(find.text('Salmos 23:1'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search-field')), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('No encontramos'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search-field')), 'paz');
      await tester.pumpAndSettle();
      expect(find.textContaining('resultado'), findsOneWidget);
    });

    testWidgets('guardar un versículo lo muestra y se puede deshacer', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Guardar en favoritos'));
      await tester.pumpAndSettle();
      await tapTab(tester, 'Guardados');
      expect(find.byKey(const Key('favorites-empty')), findsNothing);

      await tester.tap(find.byTooltip('Quitar de favoritos'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorites-empty')), findsNothing);
    });

    testWidgets('explorar abre un momento delicado con su nota', (
      tester,
    ) async {
      await pumpApp(tester);
      await tapTab(tester, 'Explorar');
      await tester.dragUntilVisible(
        find.text('Duelo'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.ensureVisible(find.text('Duelo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duelo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('topic-note')), findsOneWidget);
    });

    testWidgets('reflexión delicada pide confirmación antes de mostrarse', (
      tester,
    ) async {
      await pumpApp(tester);
      final ctx = tester.element(find.byKey(const Key('feed')));
      unawaited(GoRouter.of(ctx).push('/reflexion/19023004'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sensitive-gate')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('sensitive-read')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sensitive-read')));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byKey(const Key('prayer')),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.byKey(const Key('prayer')), findsOneWidget);
    });

    testWidgets('el primer arranque muestra la bienvenida de 3 pasos', (
      tester,
    ) async {
      await pumpApp(tester, firstRun: true);
      expect(find.text('Un versículo a la vez'), findsOneWidget);
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Empezar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feed')), findsOneWidget);
    });
  });

  group('letra al 200 %', () {
    const routes = [
      '/explorar',
      '/buscar',
      '/guardados',
      '/ajustes',
      '/hoy',
      '/verso/19023001',
      '/reflexion/19023001',
      '/reflexion/19023004',
      '/capitulo/19/23?verso=1',
      '/tema/momento/duelo',
      '/tema/tema/esperanza',
      '/bienvenida',
    ];
    for (final route in routes) {
      testWidgets('sin desbordes en $route', (tester) async {
        await pumpApp(tester, scale: 2.0);
        final ctx = tester.element(find.byKey(const Key('feed')));
        unawaited(GoRouter.of(ctx).push(route));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
