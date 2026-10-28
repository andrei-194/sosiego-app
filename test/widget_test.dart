import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('el feed muestra un versículo con su referencia', (tester) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('verse-text')), findsOneWidget);
    expect(find.byKey(const Key('verse-reference')), findsOneWidget);
  });

  testWidgets('deslizar hacia arriba muestra otra tarjeta', (tester) async {
    await pumpApp(tester);
    final first = tester.widget<Text>(find.byKey(const Key('verse-text'))).data;

    await tester.fling(
      find.byKey(const Key('feed')),
      const Offset(0, -600),
      2000,
    );
    await tester.pumpAndSettle();

    final second = tester
        .widget<Text>(find.byKey(const Key('verse-text')))
        .data;
    expect(second, isNot(first));
  });

  testWidgets('se ve bien con letra del sistema al 200 %', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('verse-text')), findsOneWidget);
  });
}
