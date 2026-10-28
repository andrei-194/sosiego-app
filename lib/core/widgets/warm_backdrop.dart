import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Degradado cálido de papel/noche, igual que el del feed.
class WarmBackdrop extends StatelessWidget {
  const WarmBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.backdrop(Theme.of(context).brightness),
        ),
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

/// Pantalla secundaria (fuera de la barra inferior): fondo cálido + SafeArea.
class SosiegoPage extends StatelessWidget {
  const SosiegoPage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: WarmBackdrop(child: SafeArea(child: child)),
  );
}
