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

  /// Aviso con «Deshacer» (spec HU-10.3).
  static const Duration undo = Duration(seconds: 5);

  /// Espera tras dejar de escribir antes de buscar (spec HU-06.8).
  static const Duration searchDebounce = Duration(milliseconds: 250);

  /// Tiempo visible para contar un versículo como visto (spec §4.6).
  static const Duration seen = Duration(seconds: 2);

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

/// Tamaños de letra base en sp, de la tabla del spec §8 (se multiplican por el
/// factor elegido; el mínimo de la interfaz es [secondary]).
class AppFont {
  /// Versículo (Lora, regular).
  static const double verse = 22;

  /// Reflexión y oración (Atkinson Hyperlegible, regular).
  static const double reading = 18;

  /// Botones y chips (Atkinson Hyperlegible, seminegrita).
  static const double action = 18;

  /// Referencia, por ejemplo Juan 3:16 (negrita).
  static const double reference = 16;

  /// Texto secundario.
  static const double secondary = 14;

  /// Texto de apoyo de la interfaz (descripciones, avisos).
  static const double body = 17;

  /// Rótulo bajo un icono: acotado a 1.3 de escala para que quepan cuatro.
  static const double iconLabel = 14;
}

/// Tope del factor de letra de los rótulos bajo un icono (barra de acciones).
const double iconLabelMaxScale = 1.3;
