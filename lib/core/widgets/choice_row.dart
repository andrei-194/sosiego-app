import 'package:flutter/material.dart';

import 'soft_card.dart';
import 'tokens.dart';

/// Fila de opción única (estilo radio) de 56 dp o más, para Ajustes.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.label,
    this.description,
    this.leading,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? description;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      checked: selected,
      button: true,
      label: description == null ? label : '$label. $description',
      excludeSemantics: true,
      onTap: onTap,
      child: SoftCard(
        onTap: onTap,
        color: selected ? context.accentWash : null,
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.s16,
          vertical: Gap.s12,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              SizedBox(
                width: 48,
                child: FittedBox(fit: BoxFit.scaleDown, child: leading),
              ),
              const SizedBox(width: Gap.s16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.label(context)),
                  if (description != null)
                    Text(description!, style: AppText.body(context)),
                ],
              ),
            ),
            const SizedBox(width: Gap.s12),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}
