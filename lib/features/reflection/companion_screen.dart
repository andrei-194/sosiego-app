import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/verse_hero.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../data/content/providers.dart';
import '../../data/user/providers.dart';
import '../../domain/content_models.dart';
import '../../l10n/l10n.dart';
import '../feed/favorites.dart';
import '../feed/verse_actions.dart';
import '../listen/listen_button.dart';
import '../share/share_sheet.dart';
import 'reflection_blocks.dart';

/// Acompañamiento (spec HU-03): con un toque en una emoción o un momento, un
/// versículo, cuatro bloques y una oración. El encabezado de la pantalla es la
/// referencia; no hay título propio de la reflexión.
class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({
    super.key,
    required this.isMoment,
    required this.slug,
  });

  final bool isMoment;
  final String slug;

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  Reflection? _reflection;
  Verse? _verse;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _pick(null);
  }

  Future<void> _pick(int? excludeId) async {
    final companion = await ref.read(getCompanionProvider.future);
    final repo = await ref.read(contentRepositoryProvider.future);
    var recent = const <int>[];
    try {
      recent = await (await ref.read(historyRepositoryProvider.future))
          .recentVerseIds();
    } catch (_) {}
    final r = widget.isMoment
        ? companion.forMoment(
            widget.slug,
            recentVerseIds: recent,
            excludeId: excludeId,
          )
        : companion.forEmotion(
            widget.slug,
            recentVerseIds: recent,
            excludeId: excludeId,
          );
    if (!mounted) return;
    setState(() {
      _reflection = r;
      _verse = r == null ? null : repo.byId(r.verseId);
      _loaded = true;
    });
  }

  void _moreOfTheme() => context.go(
    widget.isMoment
        ? '/versiculos?momento=${widget.slug}'
        : '/versiculos?tema=${widget.slug}',
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = _reflection;
    final v = _verse;
    if (!_loaded) {
      return const SosiegoPage(child: SizedBox.expand());
    }
    if (r == null || v == null) {
      return SosiegoPage(
        child: Column(
          children: [
            ScreenHeader(title: l.companionTitle),
            Expanded(
              child: EmptyState(
                icon: Icons.favorite_border,
                title: l.companionMissingTitle,
                message: l.companionMissingBody,
                actionLabel: l.companionMoreOfTheme,
                onAction: _moreOfTheme,
              ),
            ),
          ],
        ),
      );
    }
    final isFavorite = ref.watch(favoritesProvider).contains(v.id);
    return SosiegoPage(
      child: ListView(
        padding: const EdgeInsets.only(bottom: Gap.s48),
        children: [
          ScreenHeader(title: v.reference),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSize.readingWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VerseHero(
                      text: v.text,
                      reference: v.reference,
                      textKey: const Key('verse-text'),
                    ),
                    const SizedBox(height: Gap.s16),
                    Wrap(
                      spacing: Gap.s12,
                      runSpacing: Gap.s12,
                      children: [
                        ListenButton(verse: v, extraBlocks: r.blocks),
                        OutlinedButton.icon(
                          key: const Key('companion-share'),
                          onPressed: () => showShareSheet(context, verse: v),
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(l.actionShare),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.s20),
                    ReflectionBlocks(reflection: r),
                    const SizedBox(height: Gap.s24),
                    Wrap(
                      spacing: Gap.s12,
                      runSpacing: Gap.s12,
                      children: [
                        OutlinedButton.icon(
                          key: const Key('companion-save'),
                          onPressed: () => toggleFavorite(context, ref, v),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                          ),
                          label: Text(
                            isFavorite ? l.actionSaved : l.actionSave,
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const Key('companion-another'),
                          onPressed: () => _pick(r.id),
                          icon: const Icon(Icons.autorenew_rounded),
                          label: Text(l.companionAnother),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gap.s12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('companion-more'),
                        onPressed: _moreOfTheme,
                        child: Text(l.companionMoreOfTheme),
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
