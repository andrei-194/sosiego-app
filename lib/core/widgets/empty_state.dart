import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tokens.dart';

/// Estado vacío / sin resultados: un gesto cálido, qué pasa y qué hacer.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: Gap.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: icon == null
                  ? Text(
                      '“',
                      style: TextStyle(
                        fontFamily: AppTheme.verseFont,
                        fontSize: 96,
                        height: 0.9,
                        color: scheme.primary.withValues(alpha: 0.45),
                      ),
                    )
                  : Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.accentWash,
                      ),
                      child: Icon(icon, size: 40, color: scheme.primary),
                    ),
            ),
            const SizedBox(height: Gap.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.heading(context),
            ),
            const SizedBox(height: Gap.s8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(context),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: Gap.s24),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
