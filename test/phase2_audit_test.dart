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
  testWidgets('Progress lifetime totals include reviews before today', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    var clock = DateTime.now().subtract(const Duration(days: 1));
    final repository = DriftProgressRepository(db, clock: () => clock);
    final content = (await TestVocabularyRepository().loadLocal(
      // The content ID is taken from the installed real fixture.
      JlptLevel.n2,
    )).content;
    final id = content.vocabulary.keys.first;
    await repository.recordReview(id, ReviewRating.again);
    await repository.recordReview(id, ReviewRating.good);
    clock = DateTime.now();
    await repository.recordReview(id, ReviewRating.good);
    final container = ProviderContainer(
      overrides: [
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
    container.read(appRouterProvider).go('/progress');
    await tester.pumpAndSettle();
    expect(find.text('3 lifetime reviews'), findsOneWidget);
    expect(find.text('67% lifetime correct'), findsOneWidget);
  });

  testWidgets(
    'phone screens allow larger system text without layout exceptions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
      expect(tester.takeException(), isNull, reason: 'Home at larger text');
      final router = container.read(appRouterProvider);
      for (final route in [
        '/study/n2',
        '/study/n2/category/kanji',
        '/study/n2/category/kanji/source/kanji',
        '/review',
        '/progress',
        '/settings',
        '/levels',
        '/study/n2/deck/kanji?start=1',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }
      final active = (await container
          .read(progressRepositoryProvider)
          .loadActiveSession())!;
      router.go('/study/n2/word/${active.contentIds.first}');
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Word Detail at larger text',
      );
    },
  );
  testWidgets(
    'shuffle dialog cancels safely; previous/next and end operate on saved session',
    (tester) async {
      tester.view.physicalSize = const Size(457, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      container.read(appRouterProvider).go('/study/n2/deck/kanji?start=1');
      await tester.pumpAndSettle();
      final repository = container.read(progressRepositoryProvider);
      final original = (await repository.loadActiveSession())!;
      final previous = find.byKey(const Key('previous-card'));
      expect(tester.widget<IconButton>(previous).onPressed, isNull);
      final next = find.byKey(const Key('next-card'));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect((await repository.loadActiveSession())!.currentIndex, 1);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect((await repository.loadActiveSession())!.currentIndex, 0);
      await tester.ensureVisible(find.byTooltip('Shuffle cards'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Shuffle cards'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        (await repository.loadActiveSession())!.contentIds,
        original.contentIds,
      );
      expect((await repository.loadActiveSession())!.shuffleEnabled, isFalse);
      await tester.tap(find.byTooltip('Shuffle cards'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shuffle'));
      await tester.pumpAndSettle();
      final shuffled = (await repository.loadActiveSession())!;
      expect(shuffled.contentIds.toSet(), original.contentIds.toSet());
      expect(shuffled.shuffleEnabled, isTrue);
      await tester.tap(find.byTooltip('Turn shuffle off'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restore order'));
      await tester.pumpAndSettle();
      expect(
        (await repository.loadActiveSession())!.contentIds,
        original.contentIds,
      );
      await tester.tap(find.byTooltip('End session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await repository.loadActiveSession(), isNotNull);
      await tester.tap(find.byTooltip('End session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End session'));
      await tester.pumpAndSettle();
      expect(await repository.loadActiveSession(), isNull);
      expect((await repository.summary()).totalReviews, 0);
      expect(find.text('Session complete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'lifetime summary remains distinct from daily metrics and filters foreign IDs',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      var clock = DateTime(2026, 10, 7, 12);
      final repository = DriftProgressRepository(db, clock: () => clock);
      addTearDown(() async {
        await repository.close();
        await db.close();
      });
      await repository.recordReview('n2-word', ReviewRating.again);
      await repository.recordReview('n2-word', ReviewRating.easy);
      await repository.recordReview('uninstalled', ReviewRating.easy);
      clock = DateTime(2026, 10, 8, 12);
      await repository.recordReview('n2-word', ReviewRating.good);
      final summary = await repository.summary(contentIds: {'n2-word'});
      expect(summary.reviewedToday, 1);
      expect(summary.totalReviews, 1);
      expect(summary.correctReviews, 1);
      expect(summary.accuracy, 1);
      expect(summary.lifetimeReviews, 3);
      expect(summary.lifetimeCorrectReviews, 2);
      expect(summary.lifetimeAccuracy, closeTo(2 / 3, .0001));
      clock = DateTime(2026, 10, 9, 12);
      final tomorrow = await repository.summary(contentIds: {'n2-word'});
      expect(tomorrow.reviewedToday, 0);
      expect(tomorrow.lifetimeReviews, 3);
      final empty = await repository.summary(contentIds: {});
      expect(empty.lifetimeReviews, 0);
      expect(empty.lifetimeAccuracy, 0);
    },
  );
}
