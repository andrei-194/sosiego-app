import 'package:flutter_test/flutter_test.dart';

/// Las tres guías de accesibilidad del spec §7 (zonas táctiles de Android,
/// etiquetas de toque y contraste de texto). Se llama con la pantalla ya
/// abierta y asentada.
Future<void> expectMeetsAccessibilityGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  try {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  } finally {
    handle.dispose();
  }
}
