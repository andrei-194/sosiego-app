import 'package:flutter/material.dart';

import 'tokens.dart';

/// Chip en píldora de 48 dp mínimo, con emoji o icono opcional.
class SoftChip extends StatelessWidget {
  const SoftChip({
    super.key,
    required this.label,
    this.emoji,
    this.icon,
    this.selected = false,
    required this.onTap,
  });

  final String label;
  final String? emoji;
  final IconData? icon;
  final bool selected;
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
            constraints: const BoxConstraints(minHeight: AppSize.minChip),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.s16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: Gap.s8),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 20, color: scheme.primary),
                    const SizedBox(width: Gap.s8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 17,
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
