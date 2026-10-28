import 'package:go_router/go_router.dart';

import 'core/navigation/transitions.dart';
import 'features/chapter/chapter_screen.dart';
import 'features/daily/daily_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/explore/topic_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/feed/feed_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reflection/reflection_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/verse/verse_detail_screen.dart';

/// Mapa de navegación. Cuatro pestañas (feed, explorar, buscar, guardados)
/// dentro de la barra inferior; el resto son pantallas a las que se llega con
/// `push` y se vuelve con "Volver".
GoRouter buildRouter({bool firstRun = false}) => GoRouter(
  initialLocation: firstRun ? '/bienvenida' : '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/', builder: (_, _) => const FeedScreen())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explorar',
              builder: (_, _) => const ExploreScreen(),
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
      path: '/reflexion/:id',
      pageBuilder: (_, s) => softPage(
        s,
        ReflectionScreen(verseId: int.tryParse(s.pathParameters['id']!) ?? 0),
      ),
    ),
    GoRoute(
      path: '/capitulo/:book/:chapter',
      pageBuilder: (_, s) => softPage(
        s,
        ChapterScreen(
          bookId: int.tryParse(s.pathParameters['book']!) ?? 0,
          chapter: int.tryParse(s.pathParameters['chapter']!) ?? 0,
          highlightVerse: int.tryParse(s.uri.queryParameters['verso'] ?? ''),
        ),
      ),
    ),
    GoRoute(
      path: '/tema/:kind/:id',
      pageBuilder: (_, s) => softPage(
        s,
        TopicScreen(
          isMoment: s.pathParameters['kind'] == 'momento',
          id: s.pathParameters['id']!,
        ),
      ),
    ),
  ],
);
