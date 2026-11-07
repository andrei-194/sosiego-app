import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosiego/main.dart' as app;

/// Mediciones de rendimiento del spec (objetivos a validar en el dispositivo
/// de referencia, no en un emulador):
///  - HU-04.6: durante el deslizamiento menos del 5 % de cuadros superan 16 ms.
///  - HU-06.8: la búsqueda devuelve resultados en menos de 200 ms.
///  - HU-02.4: la respuesta al toque de un chip tarda menos de 300 ms.
/// El arranque en frío (< 2 s) se mide aparte con `tools/run_integration.ps1
/// startup` (adb shell am start -W), porque dentro de la prueba la app ya
/// arrancó. Los resultados se guardan en build/integration_response_data.json.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('HU-04.6 medición: cuadros lentos al deslizar el feed', (
    tester,
  ) async {
    await boot(tester);
    await tab(tester, 'Versículos');
    await binding.watchPerformance(() async {
      for (var i = 0; i < 15; i++) {
        await tester.tap(find.byKey(const Key('feed-next')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
      }
    }, reportKey: 'feed_swipe');
  });

  testWidgets('HU-06.8 medición: la búsqueda responde en menos de 200 ms', (
    tester,
  ) async {
    await boot(tester);
    await tab(tester, 'Buscar');
    final sw = Stopwatch()..start();
    await tester.enterText(find.byKey(const Key('search-field')), 'paz');
    // 250 ms de espera tras dejar de escribir + tiempo de consulta.
    await tester.pump(const Duration(milliseconds: 250));
    final afterDebounce = sw.elapsedMilliseconds;
    await tester.pumpAndSettle();
    sw.stop();
    final queryMs = sw.elapsedMilliseconds - afterDebounce;
    binding.reportData = {...?binding.reportData, 'search_query_ms': queryMs};
    // En debug (JIT, emulador) las cifras no representan al dispositivo: se
    // registran pero solo se exigen en profile o release.
    if (!kDebugMode) expect(queryMs, lessThan(200));
  });

  testWidgets('HU-02.4 medición: toque de un chip de emoción < 300 ms', (
    tester,
  ) async {
    await boot(tester);
    final chip = find.byKey(const Key('emotion-ansiedad'));
    await tester.scrollUntilVisible(
      chip,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final sw = Stopwatch()..start();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    sw.stop();
    binding.reportData = {
      ...?binding.reportData,
      'chip_tap_ms': sw.elapsedMilliseconds,
    };
    if (!kDebugMode) expect(sw.elapsedMilliseconds, lessThan(300));
  });
}
