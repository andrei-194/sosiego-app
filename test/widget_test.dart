import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  appTest('el feed muestra un versículo con su referencia', (tester) async {
    await pumpApp(tester);
    await openRoute(tester, '/versiculos');

    expect(find.byKey(const Key('verse-text')), findsOneWidget);
    expect(find.byKey(const Key('verse-reference')), findsOneWidget);
  });

  appTest('se ve bien con letra del sistema al 200 %', (tester) async {
    await pumpApp(tester, scale: 2.0);
    await openRoute(tester, '/versiculos');

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('verse-text')), findsOneWidget);
  });
}
