/// Casos de uso de la capa de dominio (spec §4). Solo interfaces: las
/// implementa la capa de datos sobre `content.db` y las pruebas pueden
/// sustituirlas.
library;

import 'content_models.dart';
import 'feed_mode.dart';
import 'verse_reference.dart';

/// Pide los siguientes versículos de la cola del feed.
class FeedRequest {
  const FeedRequest({
    required this.mode,
    required this.count,
    this.shownIds = const [],
    this.recentIds = const [],
  });

  final FeedMode mode;

  /// Cuántos versículos se quieren como máximo.
  final int count;

  /// Ids ya puestos en la cola de la sesión, en orden.
  final List<int> shownIds;

  /// Últimos vistos en `history` (del más antiguo al más reciente): no se
  /// repiten (spec §4.3).
  final List<int> recentIds;
}

abstract interface class GetNextVerse {
  /// Hasta [FeedRequest.count] versículos nuevos para el final de la cola.
  /// En los modos de lista fija devuelve los que faltan, en orden.
  List<Verse> call(FeedRequest request);
}

/// Tema o momento que coincide con lo escrito (spec HU-06.4).
class TopicMatch {
  const TopicMatch({
    required this.slug,
    required this.name,
    required this.isMoment,
  });

  final String slug;
  final String name;
  final bool isMoment;
}

/// Resultado de interpretar el campo único de búsqueda (HU-06.2).
class SearchOutcome {
  const SearchOutcome({
    this.reference,
    this.referenceVerses = const [],
    this.topic,
    this.textMatches = const [],
    this.crisis = false,
  });

  /// La entrada es una referencia que existe en la base.
  final VerseReference? reference;

  /// Versículos del capítulo o rango (la «vista de capítulo»), en orden.
  final List<Verse> referenceVerses;
  final TopicMatch? topic;
  final List<Verse> textMatches;

  /// La entrada coincide con la lista de términos de crisis (HU-13.1).
  final bool crisis;

  bool get isEmpty =>
      referenceVerses.isEmpty && topic == null && textMatches.isEmpty;

  static const empty = SearchOutcome();
}

abstract interface class SearchVerses {
  /// Resuelve en orden: referencia, tema o momento y texto. Lo escrito no se
  /// guarda en ninguna parte.
  SearchOutcome call(String query);
}

abstract interface class GetDailyContent {
  /// Contenido del día para la fecha local (`MM-DD`, incluye el 02-29).
  DailyContent? call(DateTime localDate);
}

/// Resuelve la reflexión de una emoción o un momento (HU-03.1).
abstract interface class GetCompanion {
  /// Una reflexión de la emoción [themeSlug], evitando las de versículos en
  /// [recentVerseIds]; si no queda ninguna, cualquiera del tema. Con
  /// [excludeId] no repite la que ya se está viendo («Otra palabra»).
  Reflection? forEmotion(
    String themeSlug, {
    List<int> recentVerseIds = const [],
    int? excludeId,
  });

  Reflection? forMoment(
    String momentSlug, {
    List<int> recentVerseIds = const [],
    int? excludeId,
  });
}

/// Términos que activan el bloque de ayuda en la búsqueda (HU-13.1). Lista
/// corta y provisional: PENDIENTE de revisión por el equipo editorial y, si es
/// posible, por una persona con formación en salud mental. Ya normalizados
/// (sin tildes ni mayúsculas).
const crisisTerms = <String>[
  'suicidio',
  'suicidarme',
  'quitarme la vida',
  'quiero morir',
  'ya no quiero vivir',
  'hacerme dano',
  'no puedo mas',
  'acabar con mi vida',
];

/// ¿La entrada [normalized] contiene algún término de crisis?
bool matchesCrisisTerm(String normalized) =>
    crisisTerms.any(normalized.contains);

/// Elige una reflexión entre las candidatas (spec HU-03.1): evita las de
/// versículos vistos hace poco; si no queda ninguna, elige cualquiera.
Reflection? pickReflection(
  List<Reflection> candidates, {
  required List<int> recentVerseIds,
  int? excludeId,
  required int Function(int max) nextInt,
}) {
  final others = candidates.where((r) => r.id != excludeId).toList();
  final base = others.isEmpty ? candidates : others;
  if (base.isEmpty) return null;
  final recent = recentVerseIds.toSet();
  final fresh = base.where((r) => !recent.contains(r.verseId)).toList();
  final pool = fresh.isEmpty ? base : fresh;
  return pool[nextInt(pool.length)];
}
