import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/verse_hero.dart';
import '../../core/widgets/verse_tile.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../feed/verse_actions.dart';
import '../reflection/mock_data.dart';
import 'verse_providers.dart';
import '../../l10n/l10n.dart';

/// Un versículo y todo lo que se puede hacer desde él: leer su reflexión,
/// ver el capítulo y seguir con versículos parecidos.
class VerseDetailScreen extends ConsumerWidget {
  const VerseDetailScreen({super.key, required this.verseId});

  final int verseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(verseByIdProvider(verseId));
    return SosiegoPage(
      child: verse.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _notFound(context),
        data: (v) => v == null ? _notFound(context) : _Body(verse: v),
      ),
    );
  }

  Widget _notFound(BuildContext context) => Column(
    children: [
      ScreenHeader(title: context.l10n.verseTitle),
      Expanded(
        child: EmptyState(
          title: context.l10n.verseNotFoundTitle,
          message: context.l10n.verseNotFoundBody,
          actionLabel: context.l10n.actionBack,
          onAction: () => context.pop(),
        ),
      ),
    ],
  );
}

class _Body extends ConsumerWidget {
  const _Body({required this.verse});
  final Verse verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reflection = mockReflections[verse.id];
    final repo = ref.watch(contentRepositoryProvider).valueOrNull;
    final similar = repo == null
        ? <Verse>[]
        : mockSimilarTo(verse.id).map(repo.byId).whereType<Verse>().toList();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.s32),
      children: [
        const ScreenHeader(title: ''),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.s32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerseHero(text: verse.text, reference: verse.reference),
              const SizedBox(height: Gap.s16),
              Transform.translate(
                offset: const Offset(-14, 0),
                child: VerseActions(verse: verse),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.s16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
          child: Column(
            children: [
              if (reflection != null) ...[
                SoftCard(
                  key: const Key('open-reflection'),
                  onTap: () => context.push('/reflexion/${verse.id}'),
                  color: context.accentWash,
                  semanticLabel: l.reflectionCardSemantics(
                    reflection.title,
                    reflection.readingMinutes,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_stories_outlined, color: scheme.primary),
                      const SizedBox(width: Gap.s16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reflection.title,
                              style: AppText.label(context),
                            ),
                            Text(
                              l.reflectionCardSubtitle(
                                reflection.readingMinutes,
                              ),
                              style: AppText.body(context),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.s12),
              ],
              SoftCard(
                key: const Key('open-chapter'),
                onTap: () => context.push(
                  '/capitulo/${verse.bookId}/${verse.chapter}?verso=${verse.verse}',
                ),
                semanticLabel: l.readChapterSemantics(
                  verse.bookName,
                  verse.chapter,
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, color: scheme.primary),
                    const SizedBox(width: Gap.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.readChapter, style: AppText.label(context)),
                          Text(
                            l.bookChapter(verse.bookName, verse.chapter),
                            style: AppText.body(context),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (similar.isNotEmpty) ...[
          SectionTitle(l.moreLikeThis),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
            child: Column(
              children: [
                for (final v in similar) ...[
                  VerseTile(
                    text: v.text,
                    reference: v.reference,
                    maxLines: 3,
                    onTap: () => context.push('/verso/${v.id}'),
                  ),
                  const SizedBox(height: Gap.s12),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
