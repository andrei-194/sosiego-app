import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

export '../theme/tokens.dart';

/// Superficies suaves sobre el degradado cálido (misma familia del feed).
extension SosiegoSurfaces on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get softSurface => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.62);
  Color get softBorder =>
      Theme.of(this).colorScheme.onSurface
          .withValues(alpha: isDark ? 0.14 : 0.10);
  Color get secondaryText =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.74);
  Color get accentWash =>
      Theme.of(this).colorScheme.primary
          .withValues(alpha: isDark ? 0.16 : 0.10);
}

/// Estilos de texto: Lora para lo que se lee, Atkinson para la interfaz.
class AppText {
  static TextStyle title(BuildContext c) => TextStyle(
    fontFamily: AppTheme.verseFont,
    fontSize: 32,
    height: 1.2,
    color: Theme.of(c).colorScheme.onSurface,
  );

  static TextStyle heading(BuildContext c) => TextStyle(
    fontFamily: AppTheme.verseFont,
    fontSize: 24,
    height: 1.3,
    color: Theme.of(c).colorScheme.onSurface,
  );

  static TextStyle verse(BuildContext c, {double size = AppFont.verse}) =>
      TextStyle(
        fontFamily: AppTheme.verseFont,
        fontSize: size,
        height: 1.55,
        letterSpacing: 0.1,
        color: Theme.of(c).colorScheme.onSurface,
      );

  static TextStyle reference(
    BuildContext c, {
    double size = AppFont.reference,
  }) => TextStyle(
    fontFamily: AppTheme.verseFont,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w600,
    fontSize: size,
    letterSpacing: 0.3,
    color: Theme.of(c).colorScheme.primary,
  );

  static TextStyle body(BuildContext c) =>
      TextStyle(fontSize: AppFont.body, height: 1.45, color: c.secondaryText);

  static TextStyle label(BuildContext c) => TextStyle(
    fontSize: AppFont.body,
    fontWeight: FontWeight.bold,
    color: Theme.of(c).colorScheme.onSurface,
  );
}
