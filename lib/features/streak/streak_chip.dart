import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/tokens.dart';
import '../../domain/streak.dart';
import '../../l10n/l10n.dart';
import 'streak_provider.dart';

/// Línea amable de racha en Inicio (spec HU-11): «Llevas N días contigo» con
/// N de 2 o más; «Hoy es un buen día para empezar» solo tras una racha de 2 o
/// más que se interrumpió; nada con N = 1. Sin rojo ni alertas. El detalle se
/// abre con este botón visible, no con un gesto.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(streakProvider).valueOrNull;
    if (status == null || status.display == StreakDisplay.none) {
      return const SizedBox.shrink();
    }
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final counting = status.display == StreakDisplay.counting;
    final text = counting ? l.streakCounting(status.days) : l.streakRestart;
    return Semantics(
      button: true,
      label: '$text. ${l.streakSemanticsMore}',
      excludeSemantics: true,
      onTap: () => showStreakSheet(context, status),
      child: Material(
        color: context.softSurface,
        shape: StadiumBorder(side: BorderSide(color: context.softBorder)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('streak-chip'),
          onTap: () => showStreakSheet(context, status),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.minChip),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.s16,
                vertical: Gap.s8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.spa_outlined, size: 22, color: scheme.primary),
                  const SizedBox(width: Gap.s8),
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: AppFont.secondary + 2,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showStreakSheet(BuildContext context, StreakStatus status) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) {
      final l = context.l10n;
      final scheme = Theme.of(context).colorScheme;
      final counting = status.display == StreakDisplay.counting;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Gap.s32, Gap.s8, Gap.s32, Gap.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.spa_outlined, color: scheme.primary, size: 32),
                  const SizedBox(width: Gap.s12),
                  Expanded(
                    child: Text(
                      counting
                          ? l.streakCounting(status.days)
                          : l.streakRestart,
                      style: AppText.heading(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.s16),
              Text(
                l.streakSheetBody,
                style: TextStyle(
                  fontFamily: AppTheme.verseFont,
                  fontSize: AppFont.reading + 1,
                  height: 1.55,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: Gap.s12),
              Text(l.streakSheetNote, style: AppText.body(context)),
              const SizedBox(height: Gap.s24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.streakSheetOk),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
