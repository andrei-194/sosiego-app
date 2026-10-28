import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'soft_card.dart';
import 'tokens.dart';

/// Interruptor con texto «Activado» o «Desactivado» (spec §8, para mayores).
class LabeledSwitchRow extends StatelessWidget {
  const LabeledSwitchRow({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = value ? l.switchOn : l.switchOff;
    return Semantics(
      toggled: value,
      label: '$label. $state',
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: SoftCard(
        onTap: () => onChanged(!value),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.s16,
          vertical: Gap.s12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.label(context)),
                  if (description != null)
                    Text(description!, style: AppText.body(context)),
                  Text(
                    state,
                    style: AppText.body(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: value
                          ? Theme.of(context).colorScheme.primary
                          : context.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gap.s12),
            ExcludeSemantics(
              child: Switch(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}
