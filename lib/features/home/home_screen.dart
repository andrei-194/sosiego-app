import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/card_style.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/soft_chip.dart';
import '../../core/widgets/theme_icons.dart';
import '../../core/widgets/tokens.dart';
import '../../data/content/providers.dart';
import '../../domain/content_models.dart';
import '../../l10n/l10n.dart';
import '../daily/daily_reminder_card.dart';
import '../feed/seen_recorder.dart';
import '../feed/verse_actions.dart';
import '../share/share_sheet.dart';
import '../streak/streak_chip.dart';
import '../streak/streak_provider.dart';
import 'topic_navigation.dart';

/// Las 10 emociones y los 12 momentos, de `themes` (kind = emotion) y `moments`,
/// en orden `sort` (spec HU-02.2).
final emotionsProvider = FutureProvider<List<Topic>>((ref) async {
  final repo = await ref.watch(contentRepositoryProvider.future);
  return repo.themes(kind: ThemeKind.emotion);
});

final momentsProvider = FutureProvider<List<Moment>>((ref) async {
  final repo = await ref.watch(contentRepositoryProvider.future);
  return repo.moments();
});

/// Inicio (spec D10 y HU-02): versículo de hoy, «¿Cómo te sientes hoy?» con las
/// emociones, «Momentos», la racha y la tarjeta de recordatorio. Un objetivo:
/// tocar cómo te sientes. Solo se desplaza en vertical.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final emotions = ref.watch(emotionsProvider).valueOrNull ?? const [];
    final moments = ref.watch(momentsProvider).valueOrNull ?? const [];
    final daily = ref
        .watch(getDailyContentProvider)
        .valueOrNull
        ?.call(DateTime.now());
    final streak = ref.watch(streakProvider).valueOrNull;
    return SafeArea(
      bottom: false,
      child: ListView(
        key: const Key('home'),
        padding: const EdgeInsets.only(bottom: Gap.s32),
        children: [
          ScreenHeader(title: l.appTitle, showSettings: true),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Gap.s24),
            child: Align(alignment: Alignment.centerLeft, child: StreakChip()),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(Gap.s24, Gap.s16, Gap.s24, 0),
            child: DailyReminderCard(),
          ),
          if (daily != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s16, Gap.s24, 0),
              child: SeenAfterVisible(
                verseId: daily.verse.id,
                child: _DailyCard(verse: daily.verse),
              ),
            ),
          if (daily != null && streak != null && streak.milestone)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s16, Gap.s24, 0),
              child: _MilestoneCard(days: streak.days, verse: daily.verse),
            ),
          SectionTitle(l.homeFeelingTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
            child: Wrap(
              spacing: Gap.s8,
              runSpacing: Gap.s8,
              children: [
                for (final t in emotions)
                  SoftChip(
                    key: Key('emotion-${t.slug}'),
                    label: t.name,
                    icon: contentIcon(t.icon),
                    minHeight: AppSize.minTarget,
                    onTap: () => openEmotion(context, t.slug),
                  ),
              ],
            ),
          ),
          SectionTitle(l.homeMomentsTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
            child: Wrap(
              spacing: Gap.s8,
              runSpacing: Gap.s8,
              children: [
                for (final m in moments)
                  SoftChip(
                    key: Key('moment-${m.slug}'),
                    label: m.name,
                    icon: contentIcon(m.icon),
                    minHeight: AppSize.minTarget,
                    onTap: () => openMoment(context, m.slug),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Versículo de hoy» (HU-07.2): Leer, Escuchar y Compartir, sobre el estilo
/// de fondo que le toca al versículo.
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final palette = CardStyle.forVerse(verse.id)
        .variant(Theme.of(context).brightness);
    return DecoratedBox(
      key: const Key('daily-card'),
      decoration: BoxDecoration(
        gradient: palette.gradient,
        borderRadius: BorderRadius.circular(AppRadius.block),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Gap.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.homeTodayTitle,
                style: TextStyle(
                  fontSize: AppFont.body,
                  fontWeight: FontWeight.bold,
                  color: palette.accent,
                ),
              ),
            ),
            const SizedBox(height: Gap.s12),
            Semantics(
              container: true,
              label: l.verseSemantics(verse.text, verse.reference),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verse.text,
                      style: TextStyle(
                        fontFamily: AppTheme.verseFont,
                        fontSize: AppFont.verse,
                        height: 1.55,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: Gap.s12),
                    Text(
                      verse.reference,
                      style: TextStyle(
                        fontFamily: AppTheme.verseFont,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        fontSize: AppFont.reference + 1,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.s16),
            Wrap(
              spacing: Gap.s12,
              runSpacing: Gap.s12,
              children: [
                FilledButton(
                  key: const Key('daily-read'),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.top,
                  ),
                  onPressed: () => context.push('/hoy'),
                  child: Text(l.homeRead),
                ),
                ListenOnStyle(verse: verse, color: palette.text),
                OutlinedButton.icon(
                  key: const Key('daily-share'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSize.minTarget),
                    foregroundColor: palette.text,
                    side: BorderSide(
                      color: palette.text.withValues(alpha: 0.55),
                    ),
                  ),
                  onPressed: () => showShareSheet(context, verse: verse),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(l.actionShare),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta compartible de los días 7, 30 y 100 (HU-11.4): reutiliza la hoja de
/// compartir con el titular «N días con la Palabra».
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.days, required this.verse});

  final int days;
  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SoftCard(
      key: const Key('milestone-card'),
      color: context.accentWash,
      radius: AppRadius.block,
      padding: const EdgeInsets.all(Gap.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.streakMilestoneTitle(days),
              style: AppText.heading(context),
            ),
          ),
          const SizedBox(height: Gap.s8),
          Text(l.streakMilestoneBody, style: AppText.body(context)),
          const SizedBox(height: Gap.s16),
          FilledButton.icon(
            key: const Key('milestone-share'),
            onPressed: () => showShareSheet(
              context,
              verse: verse,
              headline: l.streakMilestoneHeadline(days),
            ),
            icon: const Icon(Icons.ios_share_rounded),
            label: Text(l.streakMilestoneShare),
          ),
        ],
      ),
    );
  }
}
