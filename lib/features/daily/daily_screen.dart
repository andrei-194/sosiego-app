import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/verse_hero.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/providers.dart';
import '../../l10n/l10n.dart';
import '../feed/verse_actions.dart';
import '../reflection/reflection_blocks.dart';

/// Versículo del día completo (ruta `/hoy`, también destino de la
/// notificación): el de `daily_calendar` para la fecha local y, si el día
/// trae reflexión (fase 2), sus cuatro bloques.
class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final daily = ref.watch(getDailyContentProvider).valueOrNull?.call(today);
    final l = context.l10n;
    if (daily == null) {
      return SosiegoPage(
        child: Column(
          children: [
            ScreenHeader(title: l.homeTodayTitle),
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
        ),
      );
    }
    final verse = daily.verse;
    final reflection = daily.reflection;
    return SosiegoPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.s48),
        children: [
          ScreenHeader(title: l.homeTodayTitle, subtitle: l.longDate(today)),
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
      ),
    );
  }
}
