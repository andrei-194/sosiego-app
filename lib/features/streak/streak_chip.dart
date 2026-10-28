import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/tokens.dart';
import 'streak_provider.dart';
import '../../l10n/l10n.dart';

/// Indicador amable de racha: una píldora pequeña sobre el feed. Al tocarla
/// abre una hoja que explica que nada se pierde.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(streakProvider);
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: days <= 1 ? l.streakSemanticsFirst : l.streakSemantics(days),
      excludeSemantics: true,
      child: Material(
        color: context.softSurface,
        shape: StadiumBorder(side: BorderSide(color: context.softBorder)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showStreakSheet(context, days),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.minChip),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.s16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.spa_outlined, size: 20, color: scheme.primary),
                  const SizedBox(width: Gap.s8),
                  Flexible(
                    child: Text(
                      days <= 1 ? l.streakFirstDay : l.streakDays(days),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: scheme.onSurface),
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

void showStreakSheet(BuildContext context, int days) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) {
      final l = context.l10n;
      final scheme = Theme.of(context).colorScheme;
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
                      days <= 1
                          ? l.streakSheetTitleFirst
                          : l.streakSheetTitle(days),
                      style: AppText.heading(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.s16),
              Text(
                days <= 1 ? l.streakSheetBodyFirst : l.streakSheetBody,
                style: TextStyle(
                  fontFamily: AppTheme.verseFont,
                  fontSize: 19,
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
