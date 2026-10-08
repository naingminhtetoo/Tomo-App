import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/tomo_scaffold.dart';
import '../../features/flashcards/presentation/deck_placeholder_screen.dart';
import '../../features/level_selection/domain/jlpt_level.dart';
import '../../features/level_selection/presentation/level_selection_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/progress/presentation/review_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/study_menu/presentation/home_screen.dart';
import '../../features/study_menu/presentation/startup_screen.dart';
import '../../features/study_menu/presentation/study_menu_screen.dart';
import '../../features/vocabulary/domain/entities/deck_category.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: AppRoutes.startup,
        builder: (_, _) => const StartupScreen(),
      ),
      GoRoute(
        path: '/home',
        name: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/levels',
        name: AppRoutes.levels,
        builder: (_, _) => const LevelSelectionScreen(),
      ),
      GoRoute(
        path: '/study/:level',
        name: AppRoutes.study,
        redirect: (_, state) =>
            JlptLevel.tryParse(state.pathParameters['level']) == null
            ? '/levels'
            : null,
        builder: (_, state) => StudyMenuScreen(
          level: JlptLevel.tryParse(state.pathParameters['level'])!,
        ),
        routes: [
          GoRoute(
            path: 'deck/:category',
            name: AppRoutes.deck,
            redirect: (_, state) =>
                DeckCategory.tryParse(state.pathParameters['category']) == null
                ? '/levels'
                : null,
            builder: (_, state) => DeckPlaceholderScreen(
              deckId: state.uri.queryParameters['deck'],
              level: JlptLevel.tryParse(state.pathParameters['level'])!,
              category: DeckCategory.tryParse(
                state.pathParameters['category'],
              )!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/review',
        name: AppRoutes.review,
        builder: (_, _) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/progress',
        name: AppRoutes.progress,
        builder: (_, _) => const ProgressScreen(),
      ),
    ],
    errorBuilder: (_, _) => const FeaturePlaceholder(
      title: 'Page not found',
      message: 'This Tomo page could not be found.',
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
