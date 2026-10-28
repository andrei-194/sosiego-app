import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content/content_repository.dart';
import 'favorites.dart';
import '../../l10n/l10n.dart';
import '../../core/theme/tokens.dart';

void showToast(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: AppDuration.toast,
        action: action,
      ),
    );
}

/// Fila de acciones de un versículo: copiar, favorito y (opcional) "más".
/// La usan el feed y el detalle del versículo, con la misma apariencia.
class VerseActions extends ConsumerWidget {
  const VerseActions({super.key, required this.verse, this.onMore});

  final Verse verse;
  final VoidCallback? onMore;

  Future<void> _copy(BuildContext context) async {
    final l = context.l10n;
    await Clipboard.setData(
      ClipboardData(text: l.verseCopyText(verse.text, verse.reference)),
    );
    if (context.mounted) showToast(context, l.verseCopied);
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final added = await ref.read(favoritesProvider.notifier).toggle(verse.id);
    if (context.mounted) {
      showToast(context, added ? l.verseSavedToast : l.verseUnsavedToast);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isFavorite = ref.watch(favoritesProvider).contains(verse.id);
    final muted = scheme.onSurface.withValues(alpha: 0.75);
    return Row(
      children: [
        IconButton(
          tooltip: context.l10n.verseCopyTooltip,
          onPressed: () => _copy(context),
          icon: const Icon(Icons.content_copy_outlined, size: 26),
          color: muted,
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: isFavorite
              ? context.l10n.verseUnfavoriteTooltip
              : context.l10n.verseFavoriteTooltip,
          onPressed: () => _toggleFavorite(context, ref),
          color: isFavorite ? scheme.primary : muted,
          icon: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppDuration.quick,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isFavorite),
              size: 28,
            ),
          ),
        ),
        if (onMore != null) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: context.l10n.verseMoreTooltip,
            onPressed: onMore,
            icon: const Icon(Icons.auto_stories_outlined, size: 26),
            color: muted,
          ),
        ],
      ],
    );
  }
}
