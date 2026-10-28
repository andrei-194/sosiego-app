import 'package:flutter/material.dart';

import 'tokens.dart';

/// Acción con el texto bajo el icono (spec D12): zona táctil de 56 dp o más.
/// El rótulo no pasa de [iconLabelMaxScale] para que quepan cuatro en una
/// fila con letra muy grande, y se encoge si aun así no cabe.
class LabeledAction extends StatelessWidget {
  const LabeledAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.selected = false,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.onSurface;
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
                IconTheme(
                  data: IconThemeData(color: fg, size: 28),
                  child: icon,
                ),
                const SizedBox(height: Gap.s4),
                MediaQuery.withClampedTextScaling(
                  maxScaleFactor: iconLabelMaxScale,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: AppFont.iconLabel,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
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
