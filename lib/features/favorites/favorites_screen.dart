import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../data/content/providers.dart';
import '../../data/user/providers.dart';
import '../../domain/user_data.dart';
import '../../l10n/l10n.dart';
import '../feed/favorites.dart';
import '../feed/verse_actions.dart';
import '../listen/listen_button.dart';
import '../share/share_sheet.dart';
import 'share_favorites.dart';

/// Los últimos 100 versículos vistos, el más reciente primero (HU-10.2).
final seenEntriesProvider = FutureProvider.autoDispose<List<HistoryEntry>>((
  ref,
) async {
  try {
    final repo = await ref.watch(historyRepositoryProvider.future);
    return await repo.recent(limit: historyListLimit);
  } catch (_) {
    return const [];
  }
});

/// Guardados (spec HU-10): dos vistas, «Guardados» y «Vistos», con Compartir,
/// Escuchar y Quitar en cada elemento. Quitar no abre un diálogo: avisa 5
/// segundos con «Deshacer», que lo restituye con su fecha original.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _showSeen = false;

  Future<void> _removeFavorite(Verse v) async {
    final l = context.l10n;
    final notifier = ref.read(favoritesProvider.notifier);
    final date = await notifier.remove(v.id);
    if (!mounted) return;
    showToast(
      context,
      l.favoritesRemovedToast,
      duration: AppDuration.undo,
      action: SnackBarAction(
        label: l.actionUndo,
        onPressed: () => notifier.restore(v.id, date ?? DateTime.now()),
      ),
    );
  }

  Future<void> _removeSeen(HistoryEntry e) async {
    final l = context.l10n;
    final repo = await ref.read(historyRepositoryProvider.future);
    await repo.removeEntry(e.id);
    ref.invalidate(seenEntriesProvider);
    if (!mounted) return;
    showToast(
      context,
      l.favoritesRemovedToast,
      duration: AppDuration.undo,
      action: SnackBarAction(
        label: l.actionUndo,
        onPressed: () async {
          await repo.record(e.verseId, at: e.seenAt);
          ref.invalidate(seenEntriesProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ids = ref.watch(favoritesProvider);
    final repo = ref.watch(contentRepositoryProvider).valueOrNull;
    final favorites = repo == null
        ? <Verse>[]
        : ref
              .read(favoritesProvider.notifier)
              .entriesNewestFirst
              .map((e) => repo.byId(e.verseId))
              .whereType<Verse>()
              .toList();
    final seen = ref.watch(seenEntriesProvider).valueOrNull ?? const [];

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ScreenHeader(title: l.favoritesTitle, showSettings: true),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.s24),
              child: SegmentedButton<bool>(
                key: const Key('favorites-tabs'),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, AppSize.minTarget),
                  selectedBackgroundColor: context.accentWash,
                  textStyle: const TextStyle(fontSize: AppFont.action),
                ),
                segments: [
                  ButtonSegment(value: false, label: Text(l.favoritesTabSaved)),
                  ButtonSegment(value: true, label: Text(l.favoritesTabSeen)),
                ],
                selected: {_showSeen},
                onSelectionChanged: (s) => setState(() => _showSeen = s.first),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.s24,
                Gap.s12,
                Gap.s24,
                Gap.s4,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: context.secondaryText,
                  ),
                  const SizedBox(width: Gap.s8),
                  Expanded(
                    child: Text(
                      l.favoritesPhoneNote,
                      key: const Key('favorites-note'),
                      style: AppText.body(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ..._showSeen
              ? _list(
                  items: [
                    for (final e in seen)
                      if (repo?.byId(e.verseId) case final v?) (v, e),
                  ],
                  emptyKey: const Key('seen-empty'),
                  emptyTitle: l.seenEmptyTitle,
                  emptyBody: l.seenEmptyBody,
                )
              : _list(
                  items: [for (final v in favorites) (v, null)],
                  emptyKey: const Key('favorites-empty'),
                  emptyTitle: l.favoritesEmptyTitle,
                  emptyBody: l.favoritesEmptyBody,
                  withSend: ids.isNotEmpty,
                ),
        ],
      ),
    );
  }

  List<Widget> _list({
    required List<(Verse, HistoryEntry?)> items,
    required Key emptyKey,
    required String emptyTitle,
    required String emptyBody,
    bool withSend = false,
  }) {
    final l = context.l10n;
    if (items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            key: emptyKey,
            icon: Icons.favorite_border,
            title: emptyTitle,
            message: emptyBody,
            actionLabel: l.favoritesEmptyAction,
            onAction: () => context.go('/versiculos'),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(Gap.s24, Gap.s8, Gap.s24, Gap.s32),
        sliver: SliverList.separated(
          itemCount: items.length + (withSend ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: Gap.s12),
          itemBuilder: (context, i) {
            if (withSend && i == items.length) {
              return OutlinedButton.icon(
                key: const Key('favorites-send'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSize.minTarget),
                ),
                onPressed: () => sendMyFavorites(context, ref),
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(l.favoritesSend),
              );
            }
            final (v, entry) = items[i];
            return _Item(
              key: ValueKey('${entry?.id ?? 'f'}-${v.id}'),
              verse: v,
              onRemove: () =>
                  entry == null ? _removeFavorite(v) : _removeSeen(entry),
            );
          },
        ),
      ),
    ];
  }
}

class _Item extends StatelessWidget {
  const _Item({super.key, required this.verse, required this.onRemove});

  final Verse verse;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.all(Gap.s16),
      onTap: () => context.push('/verso/${verse.id}'),
      semanticLabel: l.verseSemantics(verse.text, verse.reference),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            verse.reference,
            style: AppText.label(context).copyWith(color: scheme.primary),
          ),
          const SizedBox(height: Gap.s8),
          Text(
            verse.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppText.verse(context),
          ),
          const SizedBox(height: Gap.s8),
          Wrap(
            spacing: Gap.s8,
            runSpacing: Gap.s4,
            children: [
              TextButton.icon(
                onPressed: () => showShareSheet(context, verse: verse),
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(l.actionShare),
              ),
              ListenButton(verse: verse),
              TextButton.icon(
                key: Key('remove-${verse.id}'),
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(l.actionRemove),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
