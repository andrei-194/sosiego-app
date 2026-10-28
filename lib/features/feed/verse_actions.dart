import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/labeled_action.dart';
import '../../core/widgets/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../l10n/l10n.dart';
import '../listen/listen_button.dart';
import '../share/share_sheet.dart';
import 'favorites.dart';

void showToast(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration duration = AppDuration.toast,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        // Con acción, Flutter lo deja fijo; aquí debe cerrarse solo (HU-10.3).
        persist: false,
      ),
    );
}

/// El botón Escuchar sobre un fondo de estilo (feed, versículo de hoy): tiñe
/// sus colores con el del texto del estilo para mantener el contraste.
class ListenOnStyle extends StatelessWidget {
  const ListenOnStyle({super.key, required this.verse, required this.color});

  final Verse verse;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(primary: color),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.55)),
          ),
        ),
      ),
      child: ListenButton(verse: verse),
    );
  }
}

/// Abre el feed con los 10 versículos parecidos a [verseId] (spec HU-05).
void openSimilar(BuildContext context, int verseId) =>
    context.go('/versiculos?parecidos=$verseId');

/// Alterna el favorito de [verse] y avisa con un mensaje breve.
Future<void> toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  Verse verse,
) async {
  final l = context.l10n;
  final added = await ref.read(favoritesProvider.notifier).toggle(verse.id);
  if (context.mounted) {
    showToast(context, added ? l.verseSavedToast : l.verseUnsavedToast);
  }
}

/// Barra de acciones de un versículo (spec HU-04.4, D12): Escuchar (botón con
/// texto) y Guardar, Compartir y «Más como este» con el texto bajo el icono. La usan el
/// feed, el versículo y la lista de una referencia.
class VerseActions extends ConsumerWidget {
  const VerseActions({
    super.key,
    required this.verse,
    this.color,
    this.showMore = true,
  });

  final Verse verse;

  /// Color de iconos y rótulos (en el feed, el del estilo del versículo).
  final Color? color;
  final bool showMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onSurface;
    final isFavorite = ref.watch(favoritesProvider).contains(verse.id);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Escuchar es el botón con texto de A-Funciones: es ancho (icono y
        // texto a un lado), así que va en su fila y no en un cuarto de fila.
        Align(
          alignment: Alignment.centerLeft,
          child: color == null
              ? ListenButton(verse: verse)
              : ListenOnStyle(verse: verse, color: fg),
        ),
        const SizedBox(height: Gap.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledAction(
                label: isFavorite ? l.actionSaved : l.actionSave,
                color: fg,
                selected: isFavorite,
                onTap: () => toggleFavorite(context, ref, verse),
                icon: AnimatedSwitcher(
                  duration: reduce ? Duration.zero : AppDuration.quick,
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorite),
                  ),
                ),
              ),
            ),
            Expanded(
              child: LabeledAction(
                label: l.actionShare,
                color: fg,
                icon: const Icon(Icons.ios_share_rounded),
                onTap: () => showShareSheet(context, verse: verse),
              ),
            ),
            if (showMore)
              Expanded(
                child: LabeledAction(
                  label: l.moreLikeThis,
                  color: fg,
                  icon: const Icon(Icons.auto_stories_outlined),
                  onTap: () => openSimilar(context, verse.id),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
