import 'package:flutter/material.dart';

import 'soft_card.dart';
import 'tokens.dart';
import '../../l10n/l10n.dart';

/// Versículo compacto para listas (búsqueda, favoritos, temas, similares).
class VerseTile extends StatelessWidget {
  const VerseTile({
    super.key,
    required this.text,
    required this.reference,
    this.onTap,
    this.trailing,
    this.maxLines = 4,
  });

  final String text;
  final String reference;
  final VoidCallback? onTap;
  final Widget? trailing;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(
        Gap.s20,
        Gap.s16,
        trailing == null ? Gap.s20 : Gap.s4,
        Gap.s16,
      ),
      semanticLabel: onTap == null
          ? null
          : context.l10n.verseSemantics(text, reference),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.verse(context, size: 19),
                ),
                const SizedBox(height: Gap.s12),
                Text(reference, style: AppText.reference(context)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
