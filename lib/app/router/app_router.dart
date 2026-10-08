import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/tomo_scaffold.dart';
import '../../features/flashcards/presentation/flashcard_screen.dart';
import '../../features/flashcards/presentation/study_controller.dart';
import '../../features/study_menu/domain/study_catalog.dart';
import '../../features/study_menu/presentation/category_screen.dart';
import '../../features/study_menu/presentation/chapter_screen.dart';
import '../../features/vocabulary/presentation/word_detail_sheet.dart';
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
            path: 'category/:kind',
            name: AppRoutes.category,
            redirect: (_, state) =>
                StudyCategory.tryParse(state.pathParameters['kind']) == null
                ? '/study/${state.pathParameters['level']}'
                : null,
            builder: (_, state) => CategoryScreen(
              level: JlptLevel.tryParse(state.pathParameters['level'])!,
              category: StudyCategory.tryParse(state.pathParameters['kind'])!,
            ),
            routes: [
              GoRoute(
                path: 'source/:source',
                name: AppRoutes.chapters,
                builder: (_, state) => ChapterScreen(
                  level: JlptLevel.tryParse(state.pathParameters['level'])!,
                  category: StudyCategory.tryParse(
                    state.pathParameters['kind'],
                  )!,
                  source: state.pathParameters['source']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'session',
            name: AppRoutes.session,
            builder: (_, state) => FlashcardScreen(
              request: studyRequest(
                level: JlptLevel.tryParse(state.pathParameters['level'])!,
                resume: true,
              ),
            ),
          ),
          GoRoute(
            path: 'word/:id',
            name: AppRoutes.word,
            builder: (_, state) => WordDetailScreen(
              level: JlptLevel.tryParse(state.pathParameters['level'])!,
              id: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'practice/:id',
            name: AppRoutes.practiceWord,
            builder: (_, state) => FlashcardScreen(
              request: studyRequest(
                level: JlptLevel.tryParse(state.pathParameters['level'])!,
                contentId: state.pathParameters['id']!,
                autoStart: true,
              ),
            ),
          ),
          GoRoute(
            path: 'review/:filter',
            name: AppRoutes.reviewStudy,
            redirect: (_, state) =>
                [
                  'due',
                  'weak',
                  'favorites',
                  'recent',
                  'mistakes',
                ].contains(state.pathParameters['filter'])
                ? null
                : '/review',
            builder: (_, state) => FlashcardScreen(
              request: studyRequest(
                level: JlptLevel.tryParse(state.pathParameters['level'])!,
                reviewFilter: state.pathParameters['filter'],
                autoStart: true,
              ),
            ),
          ),

          GoRoute(
            path: 'deck/:category',
            name: AppRoutes.deck,
            redirect: (_, state) =>
                DeckCategory.tryParse(state.pathParameters['category']) == null
                ? '/levels'
                : null,
            builder: (_, state) => FlashcardScreen(
              request: studyRequest(
                deckId: state.uri.queryParameters['deck'],
                source: state.uri.queryParameters['source'],
                autoStart: state.uri.queryParameters['start'] == '1',
                level: JlptLevel.tryParse(state.pathParameters['level'])!,
                category: DeckCategory.tryParse(
                  state.pathParameters['category'],
                )!,
              ),
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
