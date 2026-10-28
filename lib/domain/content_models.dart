// Formas de los datos de contenido que aún no tienen repositorio (temas,
// momentos, reflexiones). Reflejan las tablas de schema_content.sql.

/// Tabla `themes`: etiqueta + emoji (p. ej. "esperanza").
class Topic {
  const Topic({required this.id, required this.label, this.emoji});
  final String id;
  final String label;
  final String? emoji;
}

/// Tabla `moments`: momento de vida (p. ej. "duelo").
/// [blurb] y [delicate] NO están en el esquema: son propuesta de diseño.
class Moment {
  const Moment({
    required this.id,
    required this.label,
    required this.blurb,
    this.delicate = false,
  });
  final String id;
  final String label;
  final String blurb;
  final bool delicate;
}

enum ReflectionKind { daily, emotion, moment }

/// Tabla `reflections`.
class Reflection {
  const Reflection({
    required this.id,
    required this.verseId,
    required this.kind,
    required this.title,
    required this.body,
    required this.prayer,
    this.sensitive = false,
    required this.readingSeconds,
  });
  final int id;
  final int verseId;
  final ReflectionKind kind;
  final String title;
  final String body;
  final String prayer;
  final bool sensitive;
  final int readingSeconds;

  /// Minutos a mostrar (mínimo 1).
  int get readingMinutes => (readingSeconds / 60).ceil().clamp(1, 99);
}
