/// Entidades de contenido (spec §4, Dart puro): reflejan las tablas de
/// `content.db` del spec §6. No dependen de Flutter ni de sqlite3.
library;

/// Versículo con el nombre y el slug de su libro.
class Verse {
  const Verse({
    required this.id,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    this.bookSlug = '',
  });

  final int id;
  final int bookId;
  final String bookName;

  /// `books.slug` ('juan'), para el enlace `/v/juan-3-16`.
  final String bookSlug;
  final int chapter;
  final int verse;
  final String text;

  String get reference => '$bookName $chapter:$verse';

  /// Parte final del enlace compartible: `juan-3-16`.
  String get linkPath => '$bookSlug-$chapter-$verse';
}

enum ThemeKind { emotion, topic }

/// Tabla `themes`: emoción o tema (p. ej. «Ansiedad»).
class Topic {
  const Topic({
    required this.id,
    required this.slug,
    required this.name,
    required this.kind,
    required this.icon,
    required this.sort,
  });

  final int id;
  final String slug;
  final String name;
  final ThemeKind kind;

  /// Nombre de icono (p. ej. `waves`); la presentación lo traduce a un icono.
  final String icon;
  final int sort;
}

/// Tabla `moments`: momento de vida (p. ej. «Antes de dormir»).
class Moment {
  const Moment({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.icon,
    required this.sort,
  });

  final int id;
  final String slug;
  final String name;
  final String description;
  final String icon;
  final int sort;
}

enum ReflectionKind { daily, emotion, moment }

/// Tabla `reflections`: cuatro bloques con encabezado (spec HU-03.2). No hay
/// título propio: el encabezado de la pantalla es la referencia del versículo.
class Reflection {
  const Reflection({
    required this.id,
    required this.verseId,
    required this.kind,
    required this.contextText,
    required this.reflectionText,
    required this.applicationText,
    required this.prayerText,
    required this.readingSeconds,
    this.themeId,
    this.momentId,
    this.sensitive = false,
  });

  final int id;
  final int verseId;
  final ReflectionKind kind;
  final int? themeId;
  final int? momentId;
  final String contextText;
  final String reflectionText;
  final String applicationText;
  final String prayerText;
  final int readingSeconds;
  final bool sensitive;

  /// Minutos a mostrar (mínimo 1), a partir de `reading_seconds`.
  int get readingMinutes => (readingSeconds / 60).ceil().clamp(1, 99);

  /// Bloques en el orden de lectura (y de la voz): contexto, reflexión,
  /// aplicación y oración.
  List<String> get blocks => [
    contextText,
    reflectionText,
    applicationText,
    prayerText,
  ];
}

/// Una fila de `daily_calendar`: versículo del día y su reflexión (fase 2).
class DailyContent {
  const DailyContent({required this.verse, this.reflection});

  final Verse verse;
  final Reflection? reflection;
}
