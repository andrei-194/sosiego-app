import 'package:flutter/widgets.dart';

/// Una variante (clara u oscura) de un estilo: degradado de arriba abajo,
/// color del texto y color de acento (referencia, filetes).
class CardPalette {
  const CardPalette({
    required this.top,
    required this.bottom,
    required this.text,
    required this.accent,
  });

  final Color top;
  final Color bottom;
  final Color text;
  final Color accent;

  List<Color> get gradientColors => [top, bottom];

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: gradientColors,
  );
}

/// Estilo de fondo con nombre (spec D8): lo usan el feed y la tarjeta
/// compartida. Solo degradados cálidos, sin fotos. Cada variante cumple 7:1
/// entre el texto y cualquier punto del degradado (lo comprueba una prueba).
class CardStyle {
  const CardStyle({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
  });

  final String id;
  final String name;
  final CardPalette light;
  final CardPalette dark;

  CardPalette variant(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Los 10 estilos, en el orden en que los muestra el selector.
  static const all = <CardStyle>[
    CardStyle(
      id: 'amanecer',
      name: 'Amanecer',
      light: CardPalette(
        top: Color(0xFFFFF3E0),
        bottom: Color(0xFFF8D9B0),
        text: Color(0xFF2B1A0B),
        accent: Color(0xFF8A4B08),
      ),
      dark: CardPalette(
        top: Color(0xFF2A1A10),
        bottom: Color(0xFF4A2A14),
        text: Color(0xFFF6E7D2),
        accent: Color(0xFFF0B97A),
      ),
    ),
    CardStyle(
      id: 'noche',
      name: 'Noche',
      light: CardPalette(
        top: Color(0xFFEDEAF2),
        bottom: Color(0xFFD6D2E6),
        text: Color(0xFF1B1830),
        accent: Color(0xFF4B3F8A),
      ),
      dark: CardPalette(
        top: Color(0xFF17141F),
        bottom: Color(0xFF2A2433),
        text: Color(0xFFF3EBDD),
        accent: Color(0xFFE2B77E),
      ),
    ),
    CardStyle(
      id: 'papel',
      name: 'Papel',
      light: CardPalette(
        top: Color(0xFFFBF6EC),
        bottom: Color(0xFFF2E7D2),
        text: Color(0xFF1F1A14),
        accent: Color(0xFF8A4B08),
      ),
      dark: CardPalette(
        top: Color(0xFF14110D),
        bottom: Color(0xFF211A13),
        text: Color(0xFFF3EBDD),
        accent: Color(0xFFE2B77E),
      ),
    ),
    CardStyle(
      id: 'mar',
      name: 'Mar',
      light: CardPalette(
        top: Color(0xFFE4F0EE),
        bottom: Color(0xFFC5DEDA),
        text: Color(0xFF10302C),
        accent: Color(0xFF1F5F58),
      ),
      dark: CardPalette(
        top: Color(0xFF0F1F1E),
        bottom: Color(0xFF17332F),
        text: Color(0xFFE6F2EF),
        accent: Color(0xFF8FD0C6),
      ),
    ),
    CardStyle(
      id: 'olivo',
      name: 'Olivo',
      light: CardPalette(
        top: Color(0xFFEEF0DC),
        bottom: Color(0xFFD9DEB8),
        text: Color(0xFF232A10),
        accent: Color(0xFF4F5A12),
      ),
      dark: CardPalette(
        top: Color(0xFF171B0E),
        bottom: Color(0xFF262E15),
        text: Color(0xFFEEF1DD),
        accent: Color(0xFFC3D17A),
      ),
    ),
    CardStyle(
      id: 'alba',
      name: 'Alba',
      light: CardPalette(
        top: Color(0xFFF8E6E2),
        bottom: Color(0xFFEFCFC8),
        text: Color(0xFF3A1712),
        accent: Color(0xFF8C3326),
      ),
      dark: CardPalette(
        top: Color(0xFF261512),
        bottom: Color(0xFF3D221D),
        text: Color(0xFFF7E6E1),
        accent: Color(0xFFF0A898),
      ),
    ),
    CardStyle(
      id: 'trigo',
      name: 'Trigo',
      light: CardPalette(
        top: Color(0xFFF7EAC8),
        bottom: Color(0xFFEBD28F),
        text: Color(0xFF2C2008),
        accent: Color(0xFF6E4600),
      ),
      dark: CardPalette(
        top: Color(0xFF241B0A),
        bottom: Color(0xFF3B2C10),
        text: Color(0xFFF7EBCB),
        accent: Color(0xFFE8C46A),
      ),
    ),
    CardStyle(
      id: 'lavanda',
      name: 'Lavanda',
      light: CardPalette(
        top: Color(0xFFEDE7F3),
        bottom: Color(0xFFD9CDE8),
        text: Color(0xFF271A38),
        accent: Color(0xFF5E3A8C),
      ),
      dark: CardPalette(
        top: Color(0xFF1C1526),
        bottom: Color(0xFF2E2240),
        text: Color(0xFFEFE8F6),
        accent: Color(0xFFC9A8EE),
      ),
    ),
    CardStyle(
      id: 'brasa',
      name: 'Brasa',
      light: CardPalette(
        top: Color(0xFFF6DFD0),
        bottom: Color(0xFFE9BFA3),
        text: Color(0xFF331507),
        accent: Color(0xFF8A3A10),
      ),
      dark: CardPalette(
        top: Color(0xFF2A140A),
        bottom: Color(0xFF4A2412),
        text: Color(0xFFF8E4D4),
        accent: Color(0xFFF0A878),
      ),
    ),
    CardStyle(
      id: 'niebla',
      name: 'Niebla',
      light: CardPalette(
        top: Color(0xFFEFEDE8),
        bottom: Color(0xFFD8D5CE),
        text: Color(0xFF1E1C18),
        accent: Color(0xFF6B4A1E),
      ),
      dark: CardPalette(
        top: Color(0xFF151412),
        bottom: Color(0xFF262420),
        text: Color(0xFFF1EEE8),
        accent: Color(0xFFD8B98A),
      ),
    ),
  ];

  /// Estilo por id (el que eligió la persona al compartir); `null` si no existe.
  static CardStyle? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Estilo de un versículo: siempre el mismo para el mismo `verse_id`.
  /// Hash multiplicativo (Knuth) y sus bits altos, para que versículos
  /// consecutivos no sigan un ciclo evidente.
  static CardStyle forVerse(int verseId) {
    final h = (verseId * 2654435761) & 0xFFFFFFFF;
    return all[(h >> 16) % all.length];
  }
}
