import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/content/providers.dart';
import '../../domain/favorites_export.dart';
import '../../l10n/l10n.dart';
import '../feed/favorites.dart';

/// «Enviarme mis guardados» (spec HU-10.6): la lista como texto (referencia y
/// versículo) por la hoja de compartir del sistema, como respaldo si cambia de
/// teléfono. Usa share_plus directamente: no es una tarjeta ni va a WhatsApp.
/// Devuelve `false` si no hay nada que enviar.
Future<bool> sendMyFavorites(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final repo = await ref.read(contentRepositoryProvider.future);
  final entries = ref
      .read(favoritesProvider.notifier)
      .entriesNewestFirst
      .reversed; // del más antiguo al más reciente
  final items = [
    for (final e in entries)
      if (repo.byId(e.verseId) case final v?)
        (reference: v.reference, text: v.text),
  ];
  if (items.isEmpty) return false;
  final text = buildFavoritesExport(
    header: l.favoritesExportHeader,
    footer: l.favoritesExportFooter,
    items: items,
  );
  await SharePlus.instance.share(
    ShareParams(text: text, subject: l.favoritesExportHeader),
  );
  return true;
}
