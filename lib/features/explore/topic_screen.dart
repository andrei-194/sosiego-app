import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/verse_tile.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import 'mock_data.dart';
import '../../l10n/l10n.dart';

/// Versículos de un tema o de un momento de vida. En momentos delicados se
/// antepone una nota de acompañamiento, sin dramatizar.
class TopicScreen extends ConsumerWidget {
  const TopicScreen({super.key, required this.isMoment, required this.id});

  final bool isMoment;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final topic = isMoment ? null : mockTopic(id);
    final moment = isMoment ? mockMoment(id) : null;
    if (topic == null && moment == null) {
      return SosiegoPage(
        child: Column(
          children: [
            ScreenHeader(title: l.exploreTitle),
            Expanded(
              child: EmptyState(
                title: l.topicNotFoundTitle,
                message: l.topicNotFoundBody,
                actionLabel: l.actionBack,
                onAction: () => context.pop(),
              ),
            ),
          ],
        ),
      );
    }

    final repo = ref.watch(contentRepositoryProvider).valueOrNull;
    final verses = repo == null
        ? <Verse>[]
        : (mockTopicVerses[id] ?? const <int>[])
              .map(repo.byId)
              .whereType<Verse>()
              .toList();
    final title = topic != null
        ? '${topic.emoji ?? ''} ${topic.label}'.trim()
        : moment!.label;
    final subtitle = topic != null
        ? l.topicSubtitle(topic.label.toLowerCase())
        : moment!.blurb;
    final note = moment == null
        ? null
        : moment.delicate
        ? l.topicNoteDelicate
        : l.topicNoteGeneral;

    return SosiegoPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.s32),
        children: [
          ScreenHeader(title: title, subtitle: subtitle),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.s24,
                Gap.s12,
                Gap.s24,
                Gap.s8,
              ),
              child: SoftCard(
                key: const Key('topic-note'),
                color: context.accentWash,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: Gap.s16),
                    Expanded(child: Text(note, style: AppText.body(context))),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s16, Gap.s24, 0),
            child: Column(
              children: [
                if (verses.isEmpty)
                  SizedBox(
                    height: 280,
                    child: EmptyState(
                      icon: Icons.hourglass_empty_rounded,
                      title: l.topicEmptyTitle,
                      message: l.topicEmptyBody,
                    ),
                  ),
                for (final v in verses) ...[
                  VerseTile(
                    text: v.text,
                    reference: v.reference,
                    onTap: () => context.push('/verso/${v.id}'),
                  ),
                  const SizedBox(height: Gap.s12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
