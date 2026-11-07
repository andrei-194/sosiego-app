import 'package:flutter/material.dart';

import 'tokens.dart';

/// Acción con el texto bajo el icono (spec D12): zona táctil de 56 dp o más.
/// El rótulo no pasa de [iconLabelMaxScale] para que quepan cuatro en una
/// fila con letra muy grande, y se encoge si aun así no cabe. Con [selected]
/// el icono lleva una pastilla tenue detrás (no depende solo del color).
class LabeledAction extends StatelessWidget {
  const LabeledAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.selected = false,
    this.balanceLabel = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool selected;

  /// Parte un rótulo de varias palabras en dos líneas equilibradas («Más
  /// como / este»): así se encoge menos cuando hay cinco acciones en la fila.
  final bool balanceLabel;

  /// Parte [text] por el espacio más cercano al centro; sin espacios, igual.
  static String balanced(String text) {
    final mid = text.length / 2;
    var best = -1;
    for (var i = 0; i < text.length; i++) {
      if (text[i] != ' ') continue;
      if (best < 0 || (i - mid).abs() < (best - mid).abs()) best = i;
    }
    if (best < 0) return text;
    return '${text.substring(0, best)}\n${text.substring(best + 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.onSurface;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final style = TextStyle(
      height: 1.15,
      fontSize: AppFont.iconLabel,
      fontWeight: FontWeight.w600,
      color: fg,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.minTarget,
            minWidth: AppSize.minTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.s4,
              vertical: Gap.s8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: reduce ? Duration.zero : AppDuration.quick,
                  width: 52,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? fg.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: fg, size: 28),
                    child: icon,
                  ),
                ),
                const SizedBox(height: Gap.s4),
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: iconLabelMaxScale,
                  child: Builder(
                    builder: (context) {
                      Widget text = Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: balanceLabel ? null : 1,
                        style: style,
                      );
                      if (balanceLabel && label.contains(' ')) {
                        // Ancho justo de la línea más larga: el texto se parte
                        // solo por el espacio central, sin tocar el rótulo.
                        final painter = TextPainter(
                          text: TextSpan(
                            text: balanced(label),
                            style: DefaultTextStyle.of(context).style
                                .merge(style),
                          ),
                          textDirection: Directionality.of(context),
                          textScaler: MediaQuery.textScalerOf(context),
                        )..layout();
                        text = SizedBox(width: painter.width + 2, child: text);
                      }
                      return FittedBox(fit: BoxFit.scaleDown, child: text);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
