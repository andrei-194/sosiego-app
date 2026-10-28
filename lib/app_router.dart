import 'package:flutter/widgets.dart' show ValueKey;
import 'package:go_router/go_router.dart';

import 'core/navigation/transitions.dart';
import 'domain/feed_mode.dart';
import 'features/daily/daily_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/feed/feed_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reflection/companion_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/verse/verse_detail_screen.dart';

/// Modo del feed según la dirección: `?tema=`, `?momento=` o `?parecidos=`.
FeedMode feedModeFromUri(Uri uri) {
  final q = uri.queryParameters;
  if (q['tema'] != null) return FeedMode.theme(q['tema']!);
  if (q['momento'] != null) return FeedMode.moment(q['momento']!);
  final similar = int.tryParse(q['parecidos'] ?? '');
  if (similar != null) return FeedMode.similar(similar);
  return FeedMode.general;
}

/// Mapa de navegación (spec D10). Cuatro pestañas dentro de la barra inferior:
/// Inicio, Versículos (el feed), Buscar y Guardados. Ajustes se abre desde el
/// icono de la esquina; el resto son pantallas a las que se llega con `push` y
/// se vuelve con «Volver».
GoRouter buildRouter({bool firstRun = false}) => GoRouter(
  initialLocation: firstRun ? '/bienvenida' : '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/versiculos',
              builder: (_, s) {
                final mode = feedModeFromUri(s.uri);
                return FeedScreen(key: ValueKey(mode), mode: mode);
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/buscar', builder: (_, _) => const SearchScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/guardados',
              builder: (_, _) => const FavoritesScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/bienvenida',
      pageBuilder: (_, s) => softPage(s, const OnboardingScreen()),
    ),
    GoRoute(
      path: '/hoy',
      pageBuilder: (_, s) => softPage(s, const DailyScreen()),
    ),
    GoRoute(
      path: '/ajustes',
      pageBuilder: (_, s) => softPage(s, const SettingsScreen()),
    ),
    GoRoute(
      path: '/verso/:id',
      pageBuilder: (_, s) => softPage(
        s,
        VerseDetailScreen(verseId: int.tryParse(s.pathParameters['id']!) ?? 0),
      ),
    ),
    GoRoute(
      path: '/acompanamiento/:kind/:slug',
      pageBuilder: (_, s) => softPage(
        s,
        CompanionScreen(
          isMoment: s.pathParameters['kind'] == 'momento',
          slug: s.pathParameters['slug']!,
        ),
      ),
    ),
  ],
);
