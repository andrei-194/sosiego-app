import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/font_scale.dart';

const fontScaleKey = 'font_scale';
const themeModeKey = 'theme_mode';
const onboardingDoneKey = 'onboarding_done';
const analyticsOptInKey = 'analytics_opt_in';

/// Tamaño de letra elegido en la app (1.0 / 1.3 / 1.6).
final chosenFontScaleProvider = StateProvider<double>((_) => fontChoices.first);

/// «Ayudar a mejorar la app (anónimo)»: solo guarda la preferencia; aún no hay
/// SDK de métricas (spec §11). Por defecto desactivado.
final analyticsOptInProvider = StateProvider<bool>((_) => false);

/// Tema: sistema, claro u oscuro.
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

/// Ajustes guardados al abrir la app (se leen antes del primer fotograma).
class SavedSettings {
  const SavedSettings({
    this.fontScale = 1.0,
    this.themeMode = ThemeMode.system,
    this.onboardingDone = true,
    this.analyticsOptIn = false,
  });
  final double fontScale;
  final ThemeMode themeMode;
  final bool onboardingDone;
  final bool analyticsOptIn;

  static Future<SavedSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      // `font_scale` guarda normal, grande o muy_grande (spec §6); la fase 0
      // guardaba el factor como número.
      final raw = p.get(fontScaleKey);
      final choice = raw is String
          ? FontSizeChoice.fromKey(raw)
          : raw is double
          ? FontSizeChoice.nearest(raw)
          : null;
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(themeModeKey),
        orElse: () => ThemeMode.system,
      );
      return SavedSettings(
        fontScale: (choice ?? FontSizeChoice.normal).factor,
        themeMode: mode,
        onboardingDone: p.getBool(onboardingDoneKey) ?? false,
        analyticsOptIn: p.getBool(analyticsOptInKey) ?? false,
      );
    } catch (_) {
      return const SavedSettings();
    }
  }
}

Future<void> saveFontScale(double v) async {
  try {
    await (await SharedPreferences.getInstance()).setString(
      fontScaleKey,
      FontSizeChoice.nearest(v).key,
    );
  } catch (_) {}
}

Future<void> saveThemeMode(ThemeMode m) async {
  try {
    await (await SharedPreferences.getInstance()).setString(
      themeModeKey,
      m.name,
    );
  } catch (_) {}
}

Future<void> saveOnboardingDone() async {
  try {
    await (await SharedPreferences.getInstance()).setBool(
      onboardingDoneKey,
      true,
    );
  } catch (_) {}
}

Future<void> saveAnalyticsOptIn(bool v) async {
  try {
    await (await SharedPreferences.getInstance()).setBool(analyticsOptInKey, v);
  } catch (_) {}
}
