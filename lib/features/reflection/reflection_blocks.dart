import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/tokens.dart';
import '../../domain/content_models.dart';
import '../../l10n/l10n.dart';
import '../help/help_line_block.dart';

/// Los cuatro bloques de una reflexión con su encabezado visible (spec
/// HU-03.2): Contexto, Reflexión, Aplicación y Oración. Sin título propio.
/// Muestra el tiempo de lectura, la línea de transparencia sobre la IA y, si
/// `sensitive = 1`, el bloque de ayuda AL FINAL (HU-13): nunca oculta el
/// texto.
class ReflectionBlocks extends StatelessWidget {
  const ReflectionBlocks({super.key, required this.reflection});

  final Reflection reflection;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final entries = [
      (l.companionContext, reflection.contextText, const Key('block-context')),
      (
        l.companionReflection,
        reflection.reflectionText,
        const Key('block-reflection'),
      ),
      (
        l.companionApplication,
        reflection.applicationText,
        const Key('block-application'),
      ),
      (l.companionPrayer, reflection.prayerText, const Key('prayer')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 20,
              color: context.secondaryText,
            ),
            const SizedBox(width: Gap.s8),
            Text(
              l.readingMinutes(reflection.readingMinutes),
              key: const Key('reading-time'),
              style: AppText.body(context),
            ),
          ],
        ),
        for (final (title, body, key) in entries) ...[
          const SizedBox(height: Gap.s24),
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppText.label(context)
                  .copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: Gap.s8),
          Text(
            body,
            key: key,
            style: TextStyle(
              fontFamily: AppTheme.uiFont,
              fontSize: AppFont.reading,
              height: 1.65,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
        const SizedBox(height: Gap.s24),
        Text(
          l.companionAiLine,
          style: AppText.body(context).copyWith(fontSize: AppFont.secondary),
        ),
        if (reflection.sensitive) ...[
          const SizedBox(height: Gap.s24),
          const HelpLineBlock(),
        ],
      ],
    );
  }
}
