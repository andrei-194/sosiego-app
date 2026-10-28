import 'dart:math';

import '../../domain/content_models.dart';
import '../../domain/content_source.dart';
import '../../domain/feed_mode.dart';
import '../../domain/feed_selector.dart';
import '../../domain/text_normalizer.dart';
import '../../domain/use_cases.dart';
import '../../domain/verse_reference.dart';

/// Implementación de [GetNextVerse] sobre una [ContentSource] (spec §4).
class GetNextVerseImpl implements GetNextVerse {
  GetNextVerseImpl(this._source, {FeedSelector? selector})
    : _selector = selector ?? FeedSelector();

  final ContentSource _source;
  final FeedSelector _selector;

  List<FeedCandidate>? _eligible;

  @override
  List<Verse> call(FeedRequest request) {
    final mode = request.mode;
    final shown = request.shownIds;
    final List<int> ids;
    switch (mode.kind) {
      case FeedModeKind.general:
        ids = _pick(_eligible ??= _source.eligibleCandidates(), request);
      case FeedModeKind.theme:
        final theme = _source.themeBySlug(mode.slug ?? '');
        ids = theme == null
            ? const []
            : _pick(_source.themeCandidates(theme.id), request);
      case FeedModeKind.moment:
        final moment = _source.momentBySlug(mode.slug ?? '');
        ids = moment == null
            ? const []
            : _remaining(_source.momentVerseIds(moment.id), shown, request);
      case FeedModeKind.similar:
        ids = _remaining(_source.similarIds(mode.verseId ?? 0), shown, request);
    }
    return ids.map(_source.byId).whereType<Verse>().toList();
  }

  List<int> _remaining(List<int> ordered, List<int> shown, FeedRequest r) {
    final seen = shown.toSet();
    return ordered.where((id) => !seen.contains(id)).take(r.count).toList();
  }

  List<int> _pick(List<FeedCandidate> eligible, FeedRequest r) {
    final tail = r.shownIds.length > _selector.maxSameBookRun
        ? r.shownIds.sublist(r.shownIds.length - _selector.maxSameBookRun)
        : r.shownIds;
    return _selector.pick(
      eligible: eligible,
      recentIds: [...r.recentIds, ...r.shownIds],
      lastBooks: tail
          .map((id) => _source.byId(id)?.bookId)
          .whereType<int>()
          .toList(),
      count: r.count,
    );
  }
}

/// Implementación de [SearchVerses] (spec HU-06): referencia, luego tema o
/// momento y luego texto. Nada de lo escrito se guarda.
class SearchVersesImpl implements SearchVerses {
  SearchVersesImpl(this._source, {this.limit = 30});

  final ContentSource _source;
  final int limit;

  static String _norm(String s) =>
      normalizeText(s).replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  @override
  SearchOutcome call(String query) {
    final text = query.trim();
    if (text.isEmpty) return SearchOutcome.empty;
    final norm = _norm(text);
    final crisis = matchesCrisisTerm(norm);

    // (a) Referencia: un capítulo o un rango lista sus versículos.
    final ref = parseReference(text, index: _source.bookIndex);
    if (ref != null) {
      final verses = ref.isChapter
          ? _source.versesInRange(ref.bookId, ref.chapter)
          : _source.versesInRange(
              ref.bookId,
              ref.chapter,
              from: ref.verse,
              to: ref.verseTo ?? ref.verse,
            );
      if (verses.isNotEmpty) {
        return SearchOutcome(
          reference: ref,
          referenceVerses: verses,
          crisis: crisis,
        );
      }
    }

    // (b) Tema o momento por nombre.
    TopicMatch? topic;
    for (final t in _source.themes()) {
      if (_norm(t.name) == norm || _norm(t.slug) == norm) {
        topic = TopicMatch(slug: t.slug, name: t.name, isMoment: false);
        break;
      }
    }
    if (topic == null) {
      for (final m in _source.moments()) {
        if (_norm(m.name) == norm || _norm(m.slug) == norm) {
          topic = TopicMatch(slug: m.slug, name: m.name, isMoment: true);
          break;
        }
      }
    }

    // (c) Texto.
    return SearchOutcome(
      topic: topic,
      textMatches: _source.searchText(text, limit: limit),
      crisis: crisis,
    );
  }
}

class GetDailyContentImpl implements GetDailyContent {
  GetDailyContentImpl(this._source);
  final ContentSource _source;

  @override
  DailyContent? call(DateTime localDate) {
    final entry = _source.dailyEntry(localDate);
    if (entry == null) return null;
    final verse = _source.byId(entry.verseId);
    if (verse == null) return null;
    final rid = entry.reflectionId;
    return DailyContent(
      verse: verse,
      reflection: rid == null ? null : _source.reflectionById(rid),
    );
  }
}

class GetCompanionImpl implements GetCompanion {
  GetCompanionImpl(this._source, {Random? random})
    : _random = random ?? Random();

  final ContentSource _source;
  final Random _random;

  @override
  Reflection? forEmotion(
    String themeSlug, {
    List<int> recentVerseIds = const [],
    int? excludeId,
  }) {
    final theme = _source.themeBySlug(themeSlug);
    if (theme == null) return null;
    return pickReflection(
      _source.reflectionsForTheme(theme.id),
      recentVerseIds: recentVerseIds,
      excludeId: excludeId,
      nextInt: _random.nextInt,
    );
  }

  @override
  Reflection? forMoment(
    String momentSlug, {
    List<int> recentVerseIds = const [],
    int? excludeId,
  }) {
    final moment = _source.momentBySlug(momentSlug);
    if (moment == null) return null;
    return pickReflection(
      _source.reflectionsForMoment(moment.id),
      recentVerseIds: recentVerseIds,
      excludeId: excludeId,
      nextInt: _random.nextInt,
    );
  }
}
