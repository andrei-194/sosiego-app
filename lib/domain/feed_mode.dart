/// Modo del feed (spec §4, «Modo tema»): general o limitado por un tema, un
/// momento o los parecidos a un versículo.
enum FeedModeKind { general, theme, moment, similar }

class FeedMode {
  const FeedMode._(this.kind, {this.slug, this.verseId});

  static const general = FeedMode._(FeedModeKind.general);

  const FeedMode.theme(String slug) : this._(FeedModeKind.theme, slug: slug);
  const FeedMode.moment(String slug) : this._(FeedModeKind.moment, slug: slug);
  const FeedMode.similar(int verseId)
    : this._(FeedModeKind.similar, verseId: verseId);

  final FeedModeKind kind;

  /// Slug del tema o del momento.
  final String? slug;

  /// Versículo del que se piden los parecidos.
  final int? verseId;

  /// Los modos de lista fija terminan con una tarjeta final: momentos (por
  /// `rank`) y parecidos (los 10 de `verse_similar`).
  bool get isFinite =>
      kind == FeedModeKind.moment || kind == FeedModeKind.similar;

  @override
  bool operator ==(Object other) =>
      other is FeedMode &&
      other.kind == kind &&
      other.slug == slug &&
      other.verseId == verseId;

  @override
  int get hashCode => Object.hash(kind, slug, verseId);

  @override
  String toString() => 'FeedMode($kind, $slug, $verseId)';
}
