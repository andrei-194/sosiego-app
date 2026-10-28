import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../l10n/l10n.dart';

/// El versículo grande, con el mismo trato que en el feed: comilla decorativa,
/// texto en Lora, filete y referencia en cursiva.
class VerseHero extends StatelessWidget {
  const VerseHero({
    super.key,
    required this.text,
    required this.reference,
    this.textKey,
  });

  final String text;
  final String reference;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: context.l10n.verseSemantics(text, reference),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“',
              style: TextStyle(
                fontFamily: AppTheme.verseFont,
                fontSize: 96,
                height: 0.75,
                color: scheme.primary.withValues(alpha: 0.32),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              key: textKey,
              style: TextStyle(
                fontFamily: AppTheme.verseFont,
                fontSize: 26,
                height: 1.58,
                letterSpacing: 0.1,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 2,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    reference,
                    style: TextStyle(
                      fontFamily: AppTheme.verseFont,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      fontSize: 19,
                      letterSpacing: 0.3,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
