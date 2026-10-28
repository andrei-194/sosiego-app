import 'package:flutter/material.dart';

import 'tokens.dart';

/// Tarjeta suave: superficie translúcida con borde fino. Si recibe [onTap]
/// responde al toque con una ondulación y mide al menos 56 dp.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Gap.s20),
    this.color,
    this.radius = AppRadius.card,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: context.softBorder),
    );
    Widget card = Material(
      color: color ?? context.softSurface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.minTarget),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (semanticLabel != null) {
      card = Semantics(
        container: true,
        button: onTap != null,
        label: semanticLabel,
        excludeSemantics: true,
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
