import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../reflection/mock_data.dart';
import '../verse/verse_providers.dart';
import 'mock_data.dart';
import '../../l10n/l10n.dart';

/// Explorar: el versículo del día, temas y momentos de vida.
/// Temas y momentos son datos de muestra (ver mock_data.dart).
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.s32),
        children: [
          ScreenHeader(
            title: l.exploreTitle,
            subtitle: l.exploreSubtitle,
            showSettings: true,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(Gap.s24, Gap.s8, Gap.s24, 0),
            child: _DailyCard(),
          ),
          SectionTitle(l.exploreTopicsSection),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Gap.s24),
            child: _TopicGrid(),
          ),
          SectionTitle(l.exploreMomentsSection),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.s24, 0, Gap.s24, Gap.s12),
            child: Text(l.exploreMomentsIntro, style: AppText.body(context)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
            child: Column(
              children: [
                for (final m in mockMoments) ...[
                  SoftCard(
                    onTap: () => context.push('/tema/momento/${m.id}'),
                    semanticLabel: '${m.label}. ${m.blurb}',
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label, style: AppText.label(context)),
                              Text(m.blurb, style: AppText.body(context)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
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

/// Tarjeta destacada del versículo del día: lo más memorable de la pantalla.
class _DailyCard extends ConsumerWidget {
  const _DailyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final verse = ref.watch(verseByIdProvider(mockDailyVerseId(today)));
    return SoftCard(
      key: const Key('daily-card'),
      onTap: () => context.push('/hoy'),
      color: context.accentWash,
      radius: AppRadius.block,
      padding: const EdgeInsets.all(Gap.s24),
      semanticLabel: l.dailyCardSemantics(l.longDate(today)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: scheme.primary, size: 22),
              const SizedBox(width: Gap.s8),
              Expanded(
                child: Text(
                  l.dailyCardTitle,
                  style: AppText.label(context).copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.s12),
          verse.maybeWhen(
            data: (v) => v == null
                ? const SizedBox.shrink()
                : Text(
                    v.text,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.verseFont,
                      fontSize: 22,
                      height: 1.5,
                      color: scheme.onSurface,
                    ),
                  ),
            orElse: () => const SizedBox(height: 60),
          ),
          const SizedBox(height: Gap.s16),
          Text(l.dailyCardCta, style: AppText.reference(context, size: 17)),
        ],
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = Gap.s12;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in mockTopics)
              SizedBox(
                width: w,
                child: SoftCard(
                  onTap: () => context.push('/tema/tema/${t.id}'),
                  semanticLabel: t.label,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.s16,
                    vertical: Gap.s16,
                  ),
                  child: Row(
                    children: [
                      Text(t.emoji ?? '', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: Gap.s12),
                      Expanded(
                        child: Text(t.label, style: AppText.label(context)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
