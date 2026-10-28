/// Tokens únicos de diseño (spec D9). Ningún valor suelto en las pantallas:
/// espaciado, radios, duraciones y tamaños mínimos viven aquí.
library;

/// Escala de espaciado (múltiplos de 4 dp).
class Gap {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
}

/// Radios: tarjetas 20, bloques grandes 28 (spec rev. 2); avisos 16.
class AppRadius {
  static const double small = 16;
  static const double card = 20;
  static const double block = 28;
}

/// Duraciones. Las transiciones son de 260 ms (spec: 250 a 300); con
/// "reducir animaciones" activo se usa [Duration.zero].
class AppDuration {
  /// Transición de pantallas, páginas y desplazamientos suaves.
  static const Duration transition = Duration(milliseconds: 260);

  /// Cambios pequeños: icono de guardar, indicador de página.
  static const Duration quick = Duration(milliseconds: 220);

  /// Aparecer y desaparecer de una pista.
  static const Duration fade = Duration(milliseconds: 300);

  /// Aviso flotante (toast) visible.
  static const Duration toast = Duration(seconds: 3);

  /// Latido de la pantalla de carga.
  static const Duration pulse = Duration(milliseconds: 1600);

  /// Ciclo completo de la pista «desliza» (pausa y 3 rebotes).
  static const Duration hintCycle = Duration(milliseconds: 5100);
}

/// Tamaños mínimos (spec §7 y §8).
class AppSize {
  /// Acciones principales y zonas táctiles: 56 dp.
  static const double minTarget = 56;

  /// Chips: 48 dp como mínimo.
  static const double minChip = 48;

  /// Ancho máximo de una columna de lectura.
  static const double readingWidth = 600;
}
