import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/tokens.dart';
import '../../core/widgets/verse_tile.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../feed/favorites.dart';
import '../feed/verse_actions.dart';
import '../../l10n/l10n.dart';

/// Versículos guardados (reales: favoritesProvider + ContentRepository).
/// Quitar es inmediato y se puede deshacer.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, Verse v) async {
    final l = context.l10n;
    final notifier = ref.read(favoritesProvider.notifier);
    await notifier.toggle(v.id);
    if (!context.mounted) return;
    showToast(
      context,
      l.verseUnsavedToast,
      action: SnackBarAction(
        label: l.actionUndo,
        onPressed: () => notifier.toggle(v.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ids = ref.watch(favoritesProvider);
    final repo = ref.watch(contentRepositoryProvider).valueOrNull;
    // Lo último guardado, primero.
    final verses = repo == null
        ? <Verse>[]
        : ids.toList().reversed.map(repo.byId).whereType<Verse>().toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeader(
            title: l.favoritesTitle,
            subtitle: verses.isEmpty ? null : l.favoritesCount(verses.length),
            showSettings: true,
          ),
          Expanded(
            child: verses.isEmpty
                ? EmptyState(
                    key: const Key('favorites-empty'),
                    icon: Icons.favorite_border,
                    title: l.favoritesEmptyTitle,
                    message: l.favoritesEmptyBody,
                    actionLabel: l.favoritesEmptyAction,
                    onAction: () => context.go('/'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.s24,
                      Gap.s8,
                      Gap.s24,
                      Gap.s32,
                    ),
                    itemCount: verses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.s12),
                    itemBuilder: (context, i) {
                      final v = verses[i];
                      return Dismissible(
                        key: ValueKey(v.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _remove(context, ref, v),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: Gap.s24),
                          decoration: BoxDecoration(
                            color: context.accentWash,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Icon(
                            Icons.heart_broken_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: VerseTile(
                          text: v.text,
                          reference: v.reference,
                          onTap: () => context.push('/verso/${v.id}'),
                          trailing: IconButton(
                            tooltip: l.verseUnfavoriteTooltip,
                            onPressed: () => _remove(context, ref, v),
                            icon: Icon(
                              Icons.favorite,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
