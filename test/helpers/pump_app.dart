import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sosiego/app.dart';
import 'package:sosiego/data/content/content_repository.dart';
import 'package:sosiego/data/content/providers.dart';
import 'package:sosiego/data/user/memory_user_repositories.dart';
import 'package:sosiego/data/user/providers.dart';

/// Sustituye content.db por el de muestra y user.db por repositorios en
/// memoria: las pruebas de widgets no tocan disco ni path_provider.
List<Override> testOverrides(
  ContentRepository repo, {
  MemoryFavoritesRepository? favorites,
  MemoryActivityRepository? activity,
}) {
  final fav = favorites ?? MemoryFavoritesRepository();
  final act = activity ?? MemoryActivityRepository();
  final hist = MemoryHistoryRepository();
  final state = MemoryAppStateRepository();
  return [
    contentRepositoryProvider.overrideWith((ref) => repo),
    favoritesRepositoryProvider.overrideWith((ref) => fav),
    activityRepositoryProvider.overrideWith((ref) => act),
    historyRepositoryProvider.overrideWith((ref) => hist),
    appStateRepositoryProvider.overrideWith((ref) => state),
  ];
}

/// Abre la app. [scale] simula la letra del sistema (hasta 2.0).
Future<void> pumpApp(
  WidgetTester tester, {
  double scale = 1.0,
  bool firstRun = false,
  bool dark = false,
  Map<String, Object> prefs = const {},
  MemoryFavoritesRepository? favorites,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = const Size(1080, 2160);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (dark) {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }
  final repo = ContentRepository('assets/db/content.db');
  addTearDown(repo.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(repo, favorites: favorites),
      child: SosiegoApp(firstRun: firstRun),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}
