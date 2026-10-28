import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/content/content_repository.dart';
import 'verse_actions.dart';
import '../../l10n/l10n.dart';

/// Una tarjeta del feed: el versículo a pantalla completa, su referencia y
/// acciones discretas (copiar, guardar y "más sobre este versículo").
class VerseCard extends StatelessWidget {
  const VerseCard({super.key, required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Arriba queda libre la franja de racha y ajustes.
          final top = 56 + 16 * MediaQuery.textScalerOf(context).scale(1);
          const bottom = 96.0;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(32, top, 32, bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - top - bottom).clamp(
                  0,
                  10000,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    container: true,
                    label: context.l10n.verseSemantics(
                      verse.text,
                      verse.reference,
                    ),
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Comilla de apertura decorativa, muy sutil.
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
                            verse.text,
                            key: const Key('verse-text'),
                            style: TextStyle(
                              fontFamily: AppTheme.verseFont,
                              fontSize: 26,
                              height: 1.58,
                              letterSpacing: 0.1,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 28),
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
                                  verse.reference,
                                  key: const Key('verse-reference'),
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
                  ),
                  const SizedBox(height: 20),
                  Transform.translate(
                    // Alinea el borde visual del icono con el texto.
                    offset: const Offset(-14, 0),
                    child: VerseActions(
                      verse: verse,
                      onMore: () => context.push('/verso/${verse.id}'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
