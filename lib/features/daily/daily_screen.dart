import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/verse_hero.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../feed/verse_actions.dart';
import '../reflection/mock_data.dart';
import '../verse/verse_providers.dart';
import '../../l10n/l10n.dart';

/// Versículo del día (daily_calendar de muestra) con su reflexión.
class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final id = mockDailyVerseId(today);
    final verse = ref.watch(verseByIdProvider(id)).valueOrNull;
    final reflection = mockReflections[id];
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;

    return SosiegoPage(
      child: verse == null
          ? Column(
              children: [
                ScreenHeader(title: l.dailyFallbackTitle),
                Expanded(
                  child: EmptyState(
                    icon: Icons.wb_sunny_outlined,
                    title: l.dailyPreparingTitle,
                    message: l.dailyPreparingBody,
                    actionLabel: l.actionBack,
                    onAction: () => context.pop(),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: Gap.s32),
              children: [
                ScreenHeader(
                  title: l.dailyCardTitle,
                  subtitle: l.longDate(today),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.s32,
                    Gap.s16,
                    Gap.s32,
                    0,
                  ),
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
                if (reflection != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.s24,
                      Gap.s16,
                      Gap.s24,
                      0,
                    ),
                    child: SoftCard(
                      key: const Key('daily-reflection'),
                      onTap: () => context.push('/reflexion/${verse.id}'),
                      color: context.accentWash,
                      radius: AppRadius.block,
                      padding: const EdgeInsets.all(Gap.s24),
                      semanticLabel: l.dailyReflectionSemantics(
                        reflection.title,
                        reflection.readingMinutes,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.dailyReflectionKicker,
                            style: AppText.label(context)
                                .copyWith(color: scheme.primary),
                          ),
                          const SizedBox(height: Gap.s8),
                          Text(
                            reflection.title,
                            style: AppText.heading(context),
                          ),
                          const SizedBox(height: Gap.s8),
                          Text(
                            l.readingTime(reflection.readingMinutes),
                            style: AppText.body(context),
                          ),
                          const SizedBox(height: Gap.s16),
                          Text(
                            l.dailyReadReflection,
                            style: AppText.reference(context, size: 17),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.s24,
                    Gap.s12,
                    Gap.s24,
                    0,
                  ),
                  child: SoftCard(
                    onTap: () => context.push('/verso/${verse.id}'),
                    semanticLabel: l.dailyMoreSemantics,
                    child: Row(
                      children: [
                        Icon(Icons.explore_outlined, color: scheme.primary),
                        const SizedBox(width: Gap.s16),
                        Expanded(
                          child: Text(
                            l.moreLikeThis,
                            style: AppText.label(context),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
