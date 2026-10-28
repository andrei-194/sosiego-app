import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../domain/verse_reference.dart';
import '../../l10n/l10n.dart';

/// Capítulo completo (real: ContentRepository.chapterVerses). Si viene de un
/// versículo, ese verso queda resaltado y a la vista.
class ChapterScreen extends ConsumerStatefulWidget {
  const ChapterScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    this.highlightVerse,
  });

  final int bookId;
  final int chapter;
  final int? highlightVerse;

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  final _highlightKey = GlobalKey();
  bool _scrolled = false;

  String get _title {
    final name = bibleBooks
        .where((b) => b.id == widget.bookId)
        .map((b) => b.name)
        .firstOrNull;
    final l = context.l10n;
    return name == null
        ? l.chapterFallbackTitle
        : l.bookChapter(name, widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(contentRepositoryProvider);
    final verses =
        repoAsync.valueOrNull?.chapterVerses(widget.bookId, widget.chapter) ??
        const <Verse>[];

    if (!_scrolled && verses.isNotEmpty && widget.highlightVerse != null) {
      _scrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _highlightKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.3,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppDuration.transition,
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    return SosiegoPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(title: _title, subtitle: context.l10n.translationName),
          Expanded(
            child: verses.isEmpty
                ? EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: context.l10n.chapterNotFoundTitle,
                    message: context.l10n.chapterNotFoundBody,
                    actionLabel: context.l10n.actionBack,
                    onAction: () => context.pop(),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.s8,
                      Gap.s8,
                      Gap.s8,
                      Gap.s48,
                    ),
                    child: Column(
                      children: [
                        for (final v in verses)
                          _VerseLine(
                            key: v.verse == widget.highlightVerse
                                ? _highlightKey
                                : null,
                            verse: v,
                            highlighted: v.verse == widget.highlightVerse,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VerseLine extends StatelessWidget {
  const _VerseLine({super.key, required this.verse, required this.highlighted});

  final Verse verse;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: context.l10n.chapterVerseSemantics(
        verse.verse,
        highlighted.toString(),
        verse.text,
      ),
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: Gap.s4),
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.s16,
            vertical: Gap.s12,
          ),
          decoration: BoxDecoration(
            color: highlighted ? context.accentWash : null,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: highlighted
                ? Border(left: BorderSide(color: scheme.primary, width: 4))
                : null,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${verse.verse}  ',
                  style: TextStyle(
                    fontFamily: AppTheme.uiFont,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: scheme.primary,
                  ),
                ),
                TextSpan(text: verse.text),
              ],
            ),
            style: TextStyle(
              fontFamily: AppTheme.verseFont,
              fontSize: 21,
              height: 1.7,
              letterSpacing: 0.1,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
