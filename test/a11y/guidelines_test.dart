import 'package:flutter_test/flutter_test.dart' show group;

import '../helpers/a11y.dart';
import '../helpers/pump_app.dart';

/// Guías de accesibilidad de flutter_test sobre cada pantalla (spec §7 y §10):
/// zonas táctiles, etiquetas y contraste, en claro y en oscuro.
void main() {
  const routes = <String>[
    '/',
    '/versiculos',
    '/versiculos?tema=ansiedad',
    '/versiculos?momento=antes-de-dormir',
    '/versiculos?parecidos=43003016',
    '/buscar',
    '/guardados',
    '/ajustes',
    '/hoy',
    '/verso/19023001',
    '/acompanamiento/emocion/ansiedad',
    '/acompanamiento/emocion/tristeza', // sensible: con bloque de ayuda
    '/acompanamiento/momento/antes-de-dormir',
    '/bienvenida',
  ];

  for (final dark in [false, true]) {
    group('guías de accesibilidad ${dark ? 'en oscuro' : 'en claro'}', () {
      for (final route in routes) {
        appTest('cumple las tres guías en $route', (tester) async {
          await pumpApp(tester, dark: dark);
          if (route != '/') await openRoute(tester, route);
          await expectMeetsAccessibilityGuidelines(tester);
        });
      }
    });
  }
}
