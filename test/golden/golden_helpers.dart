import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sosiego/app.dart';
import 'package:sosiego/data/user/memory_user_repositories.dart';

import '../helpers/pump_app.dart';

/// Variante de una captura: claro, oscuro o letra del sistema al 200 %.
enum GoldenVariant {
  claro('claro', 1.0, false),
  oscuro('oscuro', 1.0, true),
  escala2('escala2', 2.0, false);

  const GoldenVariant(this.suffix, this.scale, this.dark);
  final String suffix;
  final double scale;
  final bool dark;
}

/// Fechas fijas: los golden no deben depender del reloj.
final DateTime goldenDay = DateTime(2026, 10, 20, 9);

/// Favoritos de muestra con fecha fija (versículos del salmo 23 y de Juan 3).
Future<MemoryFavoritesRepository> sampleFavorites() async {
  final favs = MemoryFavoritesRepository();
  await favs.add(19023001, createdAt: goldenDay);
  await favs.add(43003016, createdAt: goldenDay.add(const Duration(days: 1)));
  await favs.add(50004006, createdAt: goldenDay.add(const Duration(days: 2)));
  return favs;
}

/// Carga las fuentes reales: sin esto flutter_test dibuja bloques (Ahem) y los
/// golden no sirven para revisar a ojo. Material Icons sale del SDK de Flutter.
Future<void> loadGoldenFonts() async {
  Future<void> load(String family, List<Future<ByteData>> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(f);
    }
    await loader.load();
  }

  Future<ByteData> asset(String p) => rootBundle.load(p);
  await load('Lora', [
    asset('assets/fonts/Lora-Variable.ttf'),
    asset('assets/fonts/Lora-Italic-Variable.ttf'),
  ]);
  await load('AtkinsonHyperlegible', [
    asset('assets/fonts/AtkinsonHyperlegible-Regular.ttf'),
    asset('assets/fonts/AtkinsonHyperlegible-Italic.ttf'),
    asset('assets/fonts/AtkinsonHyperlegible-Bold.ttf'),
  ]);
  final root = Platform.environment['FLUTTER_ROOT'] ?? '.fvm/flutter_sdk';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> disk(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());
  await load('Roboto', [
    disk('roboto-regular.ttf'),
    disk('roboto-medium.ttf'),
    disk('roboto-bold.ttf'),
  ]);
  await load('MaterialIcons', [disk('materialicons-regular.otf')]);
}

/// Abre [route] en la [variant] y compara con `goldens/<name>_<variante>.png`.
///
/// Los golden se versionan con el sistema donde se generaron: el spec (sección
/// 10) exige regenerarlos siempre en Linux (CI). En otro sistema el texto se
/// dibuja con pequeñas diferencias; ver docs/pruebas-calidad.md.
Future<void> expectGolden(
  WidgetTester tester, {
  required String name,
  required String route,
  required GoldenVariant variant,
  MemoryFavoritesRepository? favorites,
}) async {
  await tester.runAsync(loadGoldenFonts);
  await pumpApp(
    tester,
    scale: variant.scale,
    dark: variant.dark,
    favorites: favorites,
    prefs: const {'onboarding_done': true},
  );
  await openRoute(tester, route);
  await expectLater(
    find.byType(SosiegoApp),
    matchesGoldenFile('goldens/${name}_${variant.suffix}.png'),
  );
}
