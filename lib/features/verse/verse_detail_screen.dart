import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/verse_hero.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../l10n/l10n.dart';
import '../feed/verse_actions.dart';
import '../reflection/reflection_blocks.dart';
import 'verse_providers.dart';

/// Un versículo abierto desde la búsqueda o Guardados, con sus acciones y,
/// si existe, la reflexión que lo tiene de ancla.
class VerseDetailScreen extends ConsumerWidget {
  const VerseDetailScreen({super.key, required this.verseId});

  final int verseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(verseByIdProvider(verseId));
    return SosiegoPage(
      child: verse.when(
        loading: () => const SizedBox.expand(),
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
    final repo = ref.watch(contentRepositoryProvider).valueOrNull;
    final reflection = repo?.reflectionForVerse(verse.id);
    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.s48),
      children: [
        ScreenHeader(title: context.l10n.verseTitle),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSize.readingWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VerseHero(
                    text: verse.text,
                    reference: verse.reference,
                    textKey: const Key('verse-text'),
                  ),
                  const SizedBox(height: Gap.s16),
                  VerseActions(verse: verse),
                  if (reflection != null) ...[
                    const SizedBox(height: Gap.s16),
                    ReflectionBlocks(reflection: reflection),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
