import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/app.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/router/app_router.dart';
import 'package:tomo/core/database/app_database.dart';
import 'package:tomo/features/level_selection/data/app_preferences.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/progress/data/drift_progress_repository.dart';
import 'package:tomo/features/progress/domain/progress_repository.dart';

import 'support/test_repositories.dart';

void main() {
  testWidgets('Home prioritizes real available study categories', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        vocabularyRepositoryProvider.overrideWithValue(
          TestVocabularyRepository(),
        ),
        preferencesRepositoryProvider.overrideWithValue(
          AppPreferencesRepository(MemoryPreferences()),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TomoApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('What will you learn today?'), findsOneWidget);
    expect(find.text('Study Categories'), findsOneWidget);
    expect(find.text('Pick up where you left off'), findsNothing);
    expect(find.byKey(const Key('home-review-reminder')), findsNothing);
    expect(find.text('DAILY LEARNING TIP'), findsNothing);
    expect(find.text('Review Queue'), findsNothing);
    expect(find.text("Today's Learning"), findsOneWidget);

    final grammar = tester.widget<InkWell>(
      find.byKey(const Key('home-category-grammar')),
    );
    expect(grammar.onTap, isNull);
    expect(find.text('Not installed'), findsOneWidget);

    final router = container.read(appRouterProvider);
    for (final entry in {
      'vocabulary': 'Vocabulary 語彙',
      'kanji': 'Kanji 漢字',
      'adverbs': 'Adverbs 副詞',
    }.entries) {
      final category = entry.key;
      final card = find.byKey(Key('home-category-$category'));
      await tester.ensureVisible(card);
      final categoryCard = tester.widget<InkWell>(card);
      expect(categoryCard.onTap, isNotNull);
      categoryCard.onTap!();
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      router.go('/home');
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'Study Categories precede saved learning and both continuations work',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final repository = DriftProgressRepository(db);
      final content = (await TestVocabularyRepository().loadLocal(
        JlptLevel.n2,
      )).content;
      final deck = content.decks.firstWhere((item) => item.source == 'kanji');
      final preferences = AppPreferencesRepository(MemoryPreferences());
      await preferences.save(
        AppPreferences(
          lastLearning: LastLearningActivity(
            level: JlptLevel.n2,
            category: 'kanji',
            source: 'kanji',
            deckId: deck.id,
          ),
        ),
      );
      final now = DateTime.now();
      await repository.saveActiveSession(
        ActiveStudySession(
          sessionId: 'home-session',
          deckId: deck.id,
          level: 'n2',
          currentIndex: 1,
          studyMode: 'learn',
          shuffleEnabled: false,
          startedAt: now,
          updatedAt: now,
          contentIds: deck.contentIds.take(3).toList(),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          progressRepositoryProvider.overrideWithValue(repository),
          vocabularyRepositoryProvider.overrideWithValue(
            TestVocabularyRepository(),
          ),
          preferencesRepositoryProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.close();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TomoApp()),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Study Categories')).dy,
        lessThan(tester.getTopLeft(find.text('Pick up where you left off')).dy),
      );
      expect(find.text('Kanji · Kanji（総まとめ）'), findsOneWidget);
      expect(find.text('第１週'), findsOneWidget);
      expect(find.byKey(const Key('resume-flashcards')), findsOneWidget);

      final router = container.read(appRouterProvider);
      await tester.ensureVisible(
        find.byKey(const Key('continue-learning-card')),
      );
      tester
          .widget<InkWell>(find.byKey(const Key('continue-learning-card')))
          .onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Learning List'), findsOneWidget);

      router.go('/home');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('resume-flashcards')));
      await tester.tap(find.byKey(const Key('resume-flashcards')));
      await tester.pumpAndSettle();
      expect(find.text('Learn Mode'), findsOneWidget);
      expect(find.textContaining('2 / '), findsOneWidget);
    },
  );

  testWidgets('due reminder and today statistics use saved activity', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.now();
    final repository = DriftProgressRepository(db, clock: () => now);
    final content = (await TestVocabularyRepository().loadLocal(
      JlptLevel.n2,
    )).content;
    await repository.recordReview(
      content.vocabulary.keys.first,
      ReviewRating.good,
      nextReviewAt: now,
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        progressRepositoryProvider.overrideWithValue(repository),
        vocabularyRepositoryProvider.overrideWithValue(
          TestVocabularyRepository(),
        ),
        preferencesRepositoryProvider.overrideWithValue(
          AppPreferencesRepository(MemoryPreferences()),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TomoApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 word ready for review'), findsOneWidget);
    for (final key in [
      'learned-today-stat',
      'reviewed-today-stat',
      'streak-stat',
    ]) {
      expect(
        find.descendant(of: find.byKey(Key(key)), matching: find.text('1')),
        findsOneWidget,
      );
    }
    await tester.ensureVisible(find.byKey(const Key('home-review-reminder')));
    await tester.tap(find.byKey(const Key('home-review-reminder')));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/review',
    );
  });

  for (final width in [320.0, 457.0]) {
    testWidgets('conditional Home sections fit ${width}px at 1.4x text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.now();
      final repository = DriftProgressRepository(db, clock: () => now);
      final content = (await TestVocabularyRepository().loadLocal(
        JlptLevel.n2,
      )).content;
      final deck = content.decks.firstWhere((item) => item.source == 'kanji');
      await repository.recordReview(
        deck.contentIds.first,
        ReviewRating.good,
        nextReviewAt: now,
      );
      await repository.saveActiveSession(
        ActiveStudySession(
          sessionId: 'responsive-$width',
          deckId: deck.id,
          level: 'n2',
          currentIndex: 0,
          studyMode: 'learn',
          shuffleEnabled: false,
          startedAt: now,
          updatedAt: now,
          contentIds: deck.contentIds.take(2).toList(),
        ),
      );
      final preferences = AppPreferencesRepository(MemoryPreferences());
      await preferences.save(
        AppPreferences(
          lastLearning: LastLearningActivity(
            level: JlptLevel.n2,
            category: 'kanji',
            source: 'kanji',
            deckId: deck.id,
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          progressRepositoryProvider.overrideWithValue(repository),
          vocabularyRepositoryProvider.overrideWithValue(
            TestVocabularyRepository(),
          ),
          preferencesRepositoryProvider.overrideWithValue(preferences),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await repository.close();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TomoApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Study Categories'), findsOneWidget);
      expect(find.text('Pick up where you left off'), findsOneWidget);
      expect(find.text('1 word ready for review'), findsOneWidget);
      expect(find.text("Today's Learning"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
