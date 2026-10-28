import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../helpers/a11y.dart';
import '../helpers/pump_app.dart';

/// Guías de accesibilidad de flutter_test sobre cada pantalla (spec §7 y §10).
/// Cada ruta se prueba con la letra por defecto. Lo que hoy falla queda como
/// `skip` con su razón, para no perderlo de vista.
void main() {
  const routes = <String, String?>{
    '/': null,
    '/explorar': null,
    '/buscar': null,
    '/guardados': null,
    '/ajustes': null,
    '/hoy': null,
    '/verso/19023001': null,
    '/reflexion/19023001': null,
    '/reflexion/19023004': null,
    '/capitulo/19/23?verso=1': null,
    '/tema/momento/duelo': null,
    '/tema/tema/esperanza': null,
    '/bienvenida': null,
  };

  for (final dark in [false, true]) {
    group('guías de accesibilidad ${dark ? 'en oscuro' : 'en claro'}', () {
      for (final entry in routes.entries) {
        testWidgets('cumple las tres guías en ${entry.key}'
            '${entry.value == null ? '' : ' (omitida: ${entry.value})'}', (
          tester,
        ) async {
          await pumpApp(tester, dark: dark);
          if (entry.key != '/') {
            final ctx = tester.element(find.byKey(const Key('feed')));
            unawaited(GoRouter.of(ctx).push(entry.key));
            await tester.pumpAndSettle();
          }
          await expectMeetsAccessibilityGuidelines(tester);
        }, skip: entry.value != null);
      }
    });
  }
}
