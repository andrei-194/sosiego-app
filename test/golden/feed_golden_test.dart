@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import 'golden_helpers.dart';

/// Feed en claro, oscuro y letra al 200 %. Se usa el modo «parecidos» porque su
/// orden es fijo (`verse_similar.rank`); el feed general elige al azar.
/// ATENCIÓN: otro agente rediseña la UI del feed: si estos golden fallan tras
/// un cambio visual intencional, revísalos a ojo y regenéralos con
/// `flutter test --update-goldens test/golden/feed_golden_test.dart`.
void main() {
  for (final v in GoldenVariant.values) {
    appTest('golden feed parecidos (${v.suffix})', (tester) async {
      await expectGolden(
        tester,
        name: 'feed',
        route: '/versiculos?parecidos=43003016',
        variant: v,
      );
    });
  }
}
