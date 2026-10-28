import 'package:flutter/material.dart';

import 'tokens.dart';

/// Paleta cálida y de alto contraste (verso: 7:1 sobre fondo, spec §8).
class SosiegoColors {
  static const Color paper = Color(0xFFFBF6EC);
  static const Color paperDeep = Color(0xFFF2E7D2);
  static const Color ink = Color(0xFF1F1A14);
  static const Color accent = Color(0xFF8A4B08);
  static const Color night = Color(0xFF14110D);
  static const Color nightDeep = Color(0xFF211A13);
  static const Color nightInk = Color(0xFFF3EBDD);
  static const Color nightAccent = Color(0xFFE2B77E);
}

class AppTheme {
  static const String verseFont = 'Lora';
  static const String uiFont = 'AtkinsonHyperlegible';

  static ThemeData light() => _build(
    ColorScheme.fromSeed(
      seedColor: SosiegoColors.accent,
      brightness: Brightness.light,
    ).copyWith(
      surface: SosiegoColors.paper,
      onSurface: SosiegoColors.ink,
      primary: SosiegoColors.accent,
    ),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: SosiegoColors.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: SosiegoColors.night,
      onSurface: SosiegoColors.nightInk,
      primary: SosiegoColors.nightAccent,
    ),
  );

  /// Degradado de fondo del feed: papel que se calienta hacia abajo.
  static List<Color> backdrop(Brightness b) => b == Brightness.dark
      ? const [SosiegoColors.night, SosiegoColors.nightDeep]
      : const [SosiegoColors.paper, SosiegoColors.paperDeep];

  static ThemeData _build(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: uiFont,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(AppSize.minTarget, AppSize.minTarget),
        padding: const EdgeInsets.symmetric(horizontal: 28),
        textStyle: const TextStyle(
          fontFamily: uiFont,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(AppSize.minTarget, AppSize.minTarget),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.onSurface,
      contentTextStyle: TextStyle(
        fontFamily: uiFont,
        fontSize: 16,
        color: scheme.surface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),
  );
}
