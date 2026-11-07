import 'package:integration_test/integration_test_driver.dart';

/// Driver de `flutter drive`: guarda `reportData` en
/// build/integration_response_data.json (cuadros lentos, tiempos).
Future<void> main() => integrationDriver();
