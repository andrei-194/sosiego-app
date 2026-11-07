import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosiego/main.dart' as app;

/// Flujo completo sin conexión (spec 7, «Funciona sin internet»; HU-01.5).
///
/// La prueba NO activa el modo avión por sí misma: se corre con el teléfono o
/// emulador ya en modo avión. `tools/run_integration.ps1 offline` lo hace con
/// adb (ver docs/pruebas-calidad.md). Si hubiera red, la prueba pasaría igual,
/// así que el script lo comprueba antes de lanzarla.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'HU-01.5 flujo completo en modo avión: bienvenida, inicio, feed, búsqueda y guardados',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Primer arranque: una pantalla, sin permisos ni cuenta.
      expect(find.byKey(const Key('welcome')), findsOneWidget);
      await tester.tap(find.byKey(const Key('welcome-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('emotion-ansiedad')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('emotion-ansiedad')), findsOneWidget);

      // Feed: avanzar con «Siguiente».
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Versículos'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feed')), findsOneWidget);
      final first = tester
          .widget<Text>(find.byKey(const Key('verse-text')))
          .data;
      await tester.tap(find.byKey(const Key('feed-next')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('verse-text'))).data,
        isNot(first),
      );

      // Búsqueda por referencia.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Buscar'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('search-field')),
        'Juan 3:16',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.textContaining('Juan 3:16'), findsWidgets);

      // Guardados (vacío) sin conexión.
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Guardados'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
      binding.reportData = {'offline_flow': 'ok'};
    },
  );
}
