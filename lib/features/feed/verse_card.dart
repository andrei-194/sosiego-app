import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/card_style.dart';
import '../../core/theme/tokens.dart';
import '../../data/content/content_repository.dart';
import '../../l10n/l10n.dart';
import 'verse_actions.dart';

/// Una página del feed (spec HU-04.1): el versículo a pantalla completa con su
/// referencia, el fondo del estilo que le toca por `verse_id`, las acciones
/// con texto y los botones Anterior y Siguiente siempre visibles.
class VerseCard extends StatelessWidget {
  const VerseCard({
    super.key,
    required this.verse,
    required this.topBar,
    required this.onPrevious,
    required this.onNext,
    this.showHint = false,
  });

  final Verse verse;

  /// Franja superior: etiqueta del modo (si hay) y Ajustes.
  final Widget topBar;

  /// `null` en la primera página: el botón se ve, pero apagado.
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  /// Ayuda «Desliza o toca Siguiente» (primeras tres páginas de la primera
  /// sesión). Es texto que se adapta al tamaño de letra: nunca se oculta.
  final bool showHint;

  /// Estilo de fondo del versículo, variante clara u oscura según el tema.
  static CardPalette paletteFor(BuildContext context, Verse verse) =>
      CardStyle.forVerse(verse.id).variant(Theme.of(context).brightness);

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(context, verse);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.gradient),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Pantalla baja (unos 720 dp de alto) o letra muy grande: el panel
            // inferior se aprieta y el versículo conserva todo el espacio. El
            // tamaño de la letra del versículo nunca se reduce.
            final compact =
                constraints.maxHeight < compactMaxHeight ||
                MediaQuery.textScalerOf(context).scale(10) >= 15;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Gap.s16,
                    compact ? Gap.s4 : Gap.s8,
                    Gap.s8,
                    Gap.s4,
                  ),
                  child: topBar,
                ),
                Expanded(
                  child: _VerseBody(
                    verse: verse,
                    palette: palette,
                    compact: compact,
                  ),
                ),
                _BottomPanel(
                  verse: verse,
                  palette: palette,
                  showHint: showHint,
                  compact: compact,
                  onPrevious: onPrevious,
                  onNext: onNext,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Por debajo de este alto útil (dp) se usa la variante compacta.
  static const double compactMaxHeight = 700;
}

class _VerseBody extends StatefulWidget {
  const _VerseBody({
    required this.verse,
    required this.palette,
    required this.compact,
  });

  final Verse verse;
  final CardPalette palette;
  final bool compact;

  @override
  State<_VerseBody> createState() => _VerseBodyState();
}

class _VerseBodyState extends State<_VerseBody> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verse = widget.verse;
    final palette = widget.palette;
    final compact = widget.compact;
    // Si el texto no cabe, se desplaza (nunca se recorta ni se encoge) y una
    // barra siempre visible avisa de que hay más.
    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: Gap.s32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSize.readingWidth,
                ),
                child: Semantics(
                  container: true,
                  label: context.l10n.verseSemantics(
                    verse.text,
                    verse.reference,
                  ),
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comilla de apertura decorativa, muy sutil.
                        Text(
                          '“',
                          style: TextStyle(
                            fontFamily: AppTheme.verseFont,
                            fontSize: compact ? 48 : 72,
                            height: 0.75,
                            color: palette.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: Gap.s4),
                        Text(
                          verse.text,
                          key: const Key('verse-text'),
                          style: TextStyle(
                            fontFamily: AppTheme.verseFont,
                            fontSize: AppFont.verse,
                            height: 1.6,
                            letterSpacing: 0.1,
                            color: palette.text,
                          ),
                        ),
                        SizedBox(height: compact ? Gap.s16 : Gap.s24),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 2,
                              decoration: BoxDecoration(
                                color: palette.accent,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(width: Gap.s12),
                            Flexible(
                              child: Text(
                                verse.reference,
                                key: const Key('verse-reference'),
                                style: TextStyle(
                                  fontFamily: AppTheme.verseFont,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppFont.reference + 3,
                                  letterSpacing: 0.3,
                                  color: palette.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel inferior en tres niveles: ayuda (si hay), bandeja de acciones
/// (Escuchar, Guardar, Compartir y Más como este, en una fila) y, debajo y más
/// grandes, Anterior y Siguiente, que son lo que más se toca.
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.verse,
    required this.palette,
    required this.showHint,
    required this.compact,
    required this.onPrevious,
    required this.onNext,
  });

  final Verse verse;
  final CardPalette palette;
  final bool showHint;
  final bool compact;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Gap.s20,
        compact ? Gap.s4 : Gap.s8,
        Gap.s20,
        compact ? Gap.s12 : Gap.s20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHint)
            Padding(
              padding: EdgeInsets.only(bottom: compact ? Gap.s8 : Gap.s12),
              child: Semantics(
                label: l.feedSwipeHintSemantics,
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swipe_vertical_outlined,
                        size: 22,
                        color: palette.text.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: Gap.s8),
                      Flexible(
                        // Con letra muy grande se acota a 1.3 para que quepan
                        // la ayuda y los botones; nunca se oculta.
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: iconLabelMaxScale,
                          child: Text(
                            l.feedHint,
                            key: const Key('feed-hint'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppFont.secondary + 1,
                              color: palette.text.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          DecoratedBox(
            key: const Key('feed-actions'),
            decoration: BoxDecoration(
              color: palette.text.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: palette.text.withValues(alpha: 0.14)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Gap.s4,
                vertical: compact ? 0 : Gap.s4,
              ),
              child: VerseActions(
                verse: verse,
                color: palette.text,
                inline: true,
              ),
            ),
          ),
          SizedBox(height: compact ? Gap.s12 : Gap.s20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: FeedNavButton(
                  key: const Key('feed-previous'),
                  label: l.actionPrevious,
                  icon: Icons.keyboard_arrow_up_rounded,
                  palette: palette,
                  onPressed: onPrevious,
                ),
              ),
              const SizedBox(width: Gap.s12),
              Expanded(
                flex: 3,
                child: FeedNavButton(
                  key: const Key('feed-next'),
                  label: l.actionNext,
                  icon: Icons.keyboard_arrow_down_rounded,
                  palette: palette,
                  filled: true,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Anterior o Siguiente: 56 dp de alto, siempre visibles (HU-04.2).
class FeedNavButton extends StatelessWidget {
  const FeedNavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.palette,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final CardPalette palette;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26),
          const SizedBox(width: Gap.s4),
          Text(label, maxLines: 1),
        ],
      ),
    );
    const size = Size.fromHeight(AppSize.minTarget);
    const padding = EdgeInsets.symmetric(horizontal: Gap.s12);
    const text = TextStyle(
      fontFamily: AppTheme.uiFont,
      fontSize: AppFont.action,
      fontWeight: FontWeight.bold,
    );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: size,
          padding: padding,
          textStyle: text,
          backgroundColor: palette.accent,
          foregroundColor: palette.top,
        ),
        child: content,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: size,
        padding: padding,
        textStyle: text,
        foregroundColor: palette.text,
        disabledForegroundColor: palette.text.withValues(alpha: 0.7),
        side: BorderSide(color: palette.text.withValues(alpha: 0.55)),
      ),
      child: content,
    );
  }
}
