import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../domain/content_models.dart';
import '../verse/verse_providers.dart';
import 'mock_data.dart';
import '../../l10n/l10n.dart';

String kindLabel(AppLocalizations l, ReflectionKind k) => switch (k) {
  ReflectionKind.daily => l.reflectionKindDaily,
  ReflectionKind.emotion => l.reflectionKindEmotion,
  ReflectionKind.moment => l.reflectionKindMoment,
};

/// Lectura cómoda: título, cuerpo en Lora con buen interlineado y la oración
/// en un bloque aparte. Si la reflexión es delicada, pide un "sí" antes.
class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key, required this.verseId});

  final int verseId;

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final r = mockReflections[widget.verseId];
    final verse = ref.watch(verseByIdProvider(widget.verseId)).valueOrNull;
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;

    if (r == null) {
      return SosiegoPage(
        child: Column(
          children: [
            ScreenHeader(title: l.reflectionFallbackTitle),
            Expanded(
              child: EmptyState(
                icon: Icons.auto_stories_outlined,
                title: l.reflectionMissingTitle,
                message: l.reflectionMissingBody,
                actionLabel: l.actionBack,
                onAction: () => context.pop(),
              ),
            ),
          ],
        ),
      );
    }

    final gated = r.sensitive && !_revealed;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SosiegoPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.s48),
        children: [
          const ScreenHeader(title: ''),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSize.readingWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: Gap.s8,
                      runSpacing: Gap.s8,
                      children: [
                        _Pill(
                          icon: Icons.auto_stories_outlined,
                          label: kindLabel(l, r.kind),
                        ),
                        _Pill(
                          icon: Icons.schedule_rounded,
                          label: l.readingTime(r.readingMinutes),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.s16),
                    Semantics(
                      header: true,
                      child: Text(r.title, style: AppText.title(context)),
                    ),
                    const SizedBox(height: Gap.s24),
                    AnimatedSwitcher(
                      duration: reduce ? Duration.zero : AppDuration.transition,
                      child: gated
                          ? _Gate(
                              key: const Key('sensitive-gate'),
                              onRead: () => setState(() => _revealed = true),
                            )
                          : Column(
                              key: const Key('reflection-body'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (verse != null) ...[
                                  _QuoteBar(
                                    text: verse.text,
                                    reference: verse.reference,
                                  ),
                                  const SizedBox(height: Gap.s24),
                                ],
                                for (final p in r.body.split('\n\n')) ...[
                                  Text(
                                    p,
                                    style: TextStyle(
                                      fontFamily: AppTheme.verseFont,
                                      fontSize: 20,
                                      height: 1.75,
                                      letterSpacing: 0.1,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: Gap.s16),
                                ],
                                const SizedBox(height: Gap.s8),
                                _PrayerBlock(text: r.prayer),
                                const SizedBox(height: Gap.s24),
                                if (verse != null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(
                                          AppSize.minTarget,
                                          AppSize.minTarget,
                                        ),
                                        foregroundColor: scheme.onSurface,
                                      ),
                                      onPressed: () => context.push(
                                        '/capitulo/${verse.bookId}/${verse.chapter}?verso=${verse.verse}',
                                      ),
                                      icon: const Icon(
                                        Icons.menu_book_outlined,
                                      ),
                                      label: Text(l.readChapter),
                                    ),
                                  ),
                              ],
                            ),
                    ),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s12,
        vertical: Gap.s8,
      ),
      decoration: BoxDecoration(
        color: context.accentWash,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: Gap.s8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteBar extends StatelessWidget {
  const _QuoteBar({required this.text, required this.reference});
  final String text;
  final String reference;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Gap.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: AppText.verse(
                    context,
                    size: 19,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: Gap.s8),
                Text(reference, style: AppText.reference(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({super.key, required this.onRead});
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    return SoftCard(
      color: context.accentWash,
      radius: AppRadius.block,
      padding: const EdgeInsets.all(Gap.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            color: scheme.primary,
            size: 32,
          ),
          const SizedBox(height: Gap.s12),
          Text(l.reflectionGateTitle, style: AppText.heading(context)),
          const SizedBox(height: Gap.s8),
          Text(l.reflectionGateBody, style: AppText.body(context)),
          const SizedBox(height: Gap.s24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('sensitive-read'),
              onPressed: onRead,
              child: Text(l.reflectionGateRead),
            ),
          ),
          const SizedBox(height: Gap.s8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(AppSize.minTarget, AppSize.minTarget),
                foregroundColor: scheme.onSurface,
              ),
              onPressed: () => context.pop(),
              child: Text(
                l.reflectionGateNotNow,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La oración, en un bloque propio para distinguirla del cuerpo.
class _PrayerBlock extends StatelessWidget {
  const _PrayerBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('prayer'),
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.s24),
      decoration: BoxDecoration(
        color: context.isDark
            ? scheme.primary.withValues(alpha: 0.14)
            : SosiegoColors.paperDeep,
        borderRadius: BorderRadius.circular(AppRadius.block),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_outlined, color: scheme.primary, size: 22),
              const SizedBox(width: Gap.s8),
              Flexible(
                child: Text(
                  context.l10n.reflectionPrayerTitle,
                  style: AppText.label(context).copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.s12),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTheme.verseFont,
              fontStyle: FontStyle.italic,
              fontSize: 20,
              height: 1.7,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
