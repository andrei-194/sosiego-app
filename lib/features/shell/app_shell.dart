import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/warm_backdrop.dart';
import '../../l10n/l10n.dart';

/// Barra inferior única: Inicio, Versículos (el feed), Buscar y Guardados. Cada pestaña
/// conserva su estado (el feed no pierde su posición al volver).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded),
    (Icons.auto_stories_outlined, Icons.auto_stories),
    (Icons.search_rounded, Icons.search_rounded),
    (Icons.favorite_border, Icons.favorite),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bar = AppTheme.backdrop(Theme.of(context).brightness).last;
    // Atrás desde otra pestaña vuelve a Inicio; solo desde Inicio se sale.
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: _scaffold(context, scheme, bar),
    );
  }

  Widget _scaffold(BuildContext context, ColorScheme scheme, Color bar) {
    final l = context.l10n;
    final labels = [l.navHome, l.navVerses, l.navSearch, l.navSaved];
    return Scaffold(
      body: WarmBackdrop(child: shell),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: bar,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 68,
          indicatorColor: scheme.primary.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: AppFont.iconLabel,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: scheme.onSurface.withValues(alpha: selected ? 1 : 0.78),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 26,
              color: states.contains(WidgetState.selected)
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            for (final (i, d) in _destinations.indexed)
              NavigationDestination(
                icon: Icon(d.$1),
                selectedIcon: Icon(d.$2),
                label: labels[i],
              ),
          ],
        ),
      ),
    );
  }
}
