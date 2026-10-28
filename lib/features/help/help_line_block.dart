import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/soft_card.dart';
import '../../core/widgets/tokens.dart';
import '../../data/content/providers.dart';
import '../../l10n/l10n.dart';

/// Texto y número de la línea de ayuda, desde `meta` (`help_line_text` y
/// `help_line_number`), para actualizarlos con cada versión (spec HU-13.2).
final helpLineProvider = FutureProvider<({String text, String number})>((
  ref,
) async {
  final repo = await ref.watch(contentRepositoryProvider.future);
  return (
    text: repo.meta('help_line_text') ?? '',
    number: repo.meta('help_line_number') ?? '',
  );
});

/// Número limpio para `tel:`; vacío si no trae dígitos (p. ej. un marcador
/// de posición aún sin verificar).
String dialableNumber(String raw) => raw.replaceAll(RegExp(r'[^0-9+]'), '');

/// Bloque discreto de ayuda (spec HU-13): va al final, nunca oculta ni
/// condiciona la lectura. El botón abre el marcador; la app no llama sola.
class HelpLineBlock extends ConsumerWidget {
  const HelpLineBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final line = ref.watch(helpLineProvider).valueOrNull;
    final number = line == null ? '' : dialableNumber(line.number);
    final scheme = Theme.of(context).colorScheme;
    return SoftCard(
      key: const Key('help-block'),
      color: context.accentWash,
      radius: AppRadius.block,
      padding: const EdgeInsets.all(Gap.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.helpBlockText, style: AppText.label(context)),
          if (line != null && line.text.isNotEmpty) ...[
            const SizedBox(height: Gap.s8),
            Text(line.text, style: AppText.body(context)),
          ],
          if (number.length >= 3) ...[
            const SizedBox(height: Gap.s16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('help-call'),
                onPressed: () => launchUrl(Uri(scheme: 'tel', path: number)),
                icon: const Icon(Icons.call_outlined),
                label: Text(l.helpCallButton),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
