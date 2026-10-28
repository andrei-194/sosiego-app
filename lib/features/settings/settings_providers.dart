import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/font_scale.dart';

const fontScaleKey = 'font_scale';
const themeModeKey = 'theme_mode';
const onboardingDoneKey = 'onboarding_done';

/// Tamaño de letra elegido en la app (1.0 / 1.3 / 1.6).
final chosenFontScaleProvider = StateProvider<double>((_) => fontChoices.first);

/// Tema: sistema, claro u oscuro.
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

/// Ajustes guardados al abrir la app (se leen antes del primer fotograma).
class SavedSettings {
  const SavedSettings({
    this.fontScale = 1.0,
    this.themeMode = ThemeMode.system,
    this.onboardingDone = true,
  });
  final double fontScale;
  final ThemeMode themeMode;
  final bool onboardingDone;

  static Future<SavedSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final scale = p.getDouble(fontScaleKey) ?? fontChoices.first;
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(themeModeKey),
        orElse: () => ThemeMode.system,
      );
      return SavedSettings(
        fontScale: fontChoices.contains(scale) ? scale : fontChoices.first,
        themeMode: mode,
        onboardingDone: p.getBool(onboardingDoneKey) ?? false,
      );
    } catch (_) {
      return const SavedSettings();
    }
  }
}

Future<void> saveFontScale(double v) async {
  try {
    await (await SharedPreferences.getInstance()).setDouble(fontScaleKey, v);
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
