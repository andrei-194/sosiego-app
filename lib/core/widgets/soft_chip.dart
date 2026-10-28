import 'package:flutter/material.dart';

import 'tokens.dart';

/// Chip en píldora de 48 dp mínimo (56 dp en Inicio), con emoji o icono opcional.
class SoftChip extends StatelessWidget {
  const SoftChip({
    super.key,
    required this.label,
    this.emoji,
    this.icon,
    this.selected = false,
    this.minHeight = AppSize.minChip,
    required this.onTap,
  });

  final String label;
  final String? emoji;
  final IconData? icon;
  final bool selected;

  /// Alto mínimo: 48 dp por defecto y 56 dp en los chips de Inicio (HU-02.2).
  final double minHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? scheme.primary : context.softSurface,
        shape: StadiumBorder(side: BorderSide(color: context.softBorder)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.s16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null) ...[
                    Text(
                      emoji!,
                      style: const TextStyle(fontSize: AppFont.action),
                    ),
                    const SizedBox(width: Gap.s8),
                  ] else if (icon != null) ...[
                    Icon(
                      icon,
                      size: 22,
                      color: selected ? scheme.onPrimary : scheme.primary,
                    ),
                    const SizedBox(width: Gap.s8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: AppFont.action,
                        color: selected ? scheme.onPrimary : scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
