@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import 'golden_helpers.dart';

/// Pantallas clave en claro, oscuro y letra al 200 % (spec 10, nivel Golden).
/// El feed va aparte (feed_golden_test.dart) porque su diseño está en cambio.
void main() {
  for (final v in GoldenVariant.values) {
    appTest('golden ajustes (${v.suffix})', (tester) async {
      await expectGolden(
        tester,
        name: 'ajustes',
        route: '/ajustes',
        variant: v,
      );
    });

    appTest('golden guardados con favoritos (${v.suffix})', (tester) async {
      await expectGolden(
        tester,
        name: 'guardados',
        route: '/guardados',
        variant: v,
        favorites: await sampleFavorites(),
      );
    });

    appTest('golden guardados vacío (${v.suffix})', (tester) async {
      await expectGolden(
        tester,
        name: 'guardados_vacio',
        route: '/guardados',
        variant: v,
      );
    });
  }
}
