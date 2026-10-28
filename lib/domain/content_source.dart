/// Lectura del contenido (spec §4, regla 2): la capa de datos la implementa
/// sobre `content.db` y las pruebas pueden usar una versión en memoria.
library;

import 'content_models.dart';
import 'feed_selector.dart';
import 'verse_reference.dart';

abstract interface class ContentSource {
  /// Versículos con `is_card_eligible = 1`.
  List<FeedCandidate> eligibleCandidates();

  Verse? byId(int id);

  /// Versículos de un capítulo, o del rango [from]..[to] si se indica.
  List<Verse> versesInRange(int bookId, int chapter, {int? from, int? to});

  /// Libros con alias, para resolver referencias.
  BookIndex get bookIndex;

  List<Topic> themes({ThemeKind? kind});
  List<Moment> moments();
  Topic? themeBySlug(String slug);
  Moment? momentBySlug(String slug);

  /// Versículos del tema con peso de [minWeight] o más (spec §4.4).
  List<FeedCandidate> themeCandidates(int themeId, {double minWeight = 0.6});

  /// Ids de `moment_verses`, en orden de `rank`.
  List<int> momentVerseIds(int momentId);

  /// Ids de `verse_similar`, en orden de `rank`.
  List<int> similarIds(int verseId);

  /// Búsqueda de texto: prefijo en la última palabra, `bm25`, máximo [limit].
  List<Verse> searchText(String query, {int limit = 30});

  /// Entrada de `daily_calendar` para el día `MM-DD` de [localDate].
  ({int verseId, int? reflectionId})? dailyEntry(DateTime localDate);

  Reflection? reflectionById(int id);
  List<Reflection> reflectionsForTheme(int themeId);
  List<Reflection> reflectionsForMoment(int momentId);
  Reflection? reflectionForVerse(int verseId);

  /// Valor de `meta` (p. ej. `help_line_number`).
  String? meta(String key);
}
