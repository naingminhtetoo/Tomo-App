import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tomo/app/app.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/router/app_router.dart';
import 'package:tomo/app/theme/tomo_theme.dart';
import 'package:tomo/core/database/app_database.dart';
import 'package:tomo/features/level_selection/data/app_preferences.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/progress/domain/progress_repository.dart';
import 'package:tomo/features/study_menu/domain/study_catalog.dart';
import 'package:tomo/features/study_menu/presentation/chapter_screen.dart';

import 'support/test_repositories.dart';

void main() {
  testWidgets(
    'renders actual course data and opens the Learning List from a chapter',
    (tester) async {
      final harness = await _pumpApp(tester, width: 393);
      final source = harness.catalog
          .sources(StudyCategory.kanji)
          .firstWhere((candidate) => candidate.id == 'kanji');
      final firstDeck = source.decks.first;
      await harness.progress.recordReview(
        firstDeck.contentIds.first,
        ReviewRating.good,
      );

      harness.router.go('/study/n2/category/kanji/source/kanji');
      await tester.pumpAndSettle();

      expect(find.text(source.title), findsOneWidget);
      expect(find.text('Kanji · JLPT N2'), findsOneWidget);
      expect(
        find.text(
          '${source.decks.length} chapters · ${source.contentIds.length} items',
        ),
        findsOneWidget,
      );
      expect(
        find.text('1 / ${firstDeck.contentIds.toSet().length} learned'),
        findsOneWidget,
      );

      final summaryHeight = tester
          .getSize(find.byKey(const Key('course-summary')))
          .height;
      final row = find.byKey(Key('chapter-row-${firstDeck.id}'));
      final rowHeight = tester.getSize(row).height;
      expect(summaryHeight, lessThan(180));
      expect(rowHeight, inInclusiveRange(72, 96));

      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('Learning List'), findsOneWidget);
      expect(find.text('Practice Flashcards'), findsOneWidget);
      expect(find.text('Learn Mode'), findsNothing);
    },
  );

  testWidgets('Back to Decks returns to the learning-source screen', (
    tester,
  ) async {
    final harness = await _pumpApp(tester, width: 393);
    harness.router.go('/study/n2/category/kanji');
    await tester.pumpAndSettle();
    harness.router.push('/study/n2/category/kanji/source/kanji');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('back-to-decks')), findsOneWidget);
    await tester.tap(find.byKey(const Key('back-to-decks')));
    await tester.pumpAndSettle();

    expect(find.text('Kanji 漢字'), findsOneWidget);
    expect(find.text('Kanji（総まとめ）'), findsOneWidget);
  });

  testWidgets('secondary all-words action opens the combined Learning List', (
    tester,
  ) async {
    final harness = await _pumpApp(tester, width: 393);
    harness.router.go('/study/n2/category/kanji/source/kanji');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('browse-all-words')));
    await tester.pumpAndSettle();

    expect(find.text('Learning List'), findsOneWidget);
    expect(find.text('Practice Flashcards'), findsOneWidget);
    expect(find.text('Learn Mode'), findsNothing);
  });

  for (final width in [320.0, 393.0, 457.0]) {
    testWidgets('chapter roadmap fits ${width.toInt()}px at 1.4x text', (
      tester,
    ) async {
      final harness = await _pumpApp(
        tester,
        width: width,
        textScaleFactor: 1.4,
      );
      harness.router.go('/study/n2/category/kanji/source/kanji');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('back-to-decks')), findsOneWidget);
      final firstRow = find.byType(CompactChapterRow).first;
      expect(tester.getSize(firstRow).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(find.byType(CompactChapterRow).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final theme in <({String name, ThemeData data})>[
    (name: 'dark', data: TomoTheme.dark),
    (name: 'light', data: TomoTheme.light),
  ]) {
    testWidgets('long Japanese chapter title fits the ${theme.name} theme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 260);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme.data,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: CompactChapterRow(
                number: 12,
                title: '日本語能力試験のための長い漢字学習チャプター',
                progress: const DeckProgress(learned: 18, total: 40),
                current: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(CompactChapterRow));
      expect(size.height, greaterThanOrEqualTo(76));
      expect(size.width, lessThanOrEqualTo(280));
    });
  }
}

class _ChapterHarness {
  const _ChapterHarness({
    required this.router,
    required this.catalog,
    required this.progress,
  });

  final GoRouter router;
  final StudyCatalog catalog;
  final ProgressRepository progress;
}

Future<_ChapterHarness> _pumpApp(
  WidgetTester tester, {
  required double width,
  double textScaleFactor = 1,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final db = AppDatabase(NativeDatabase.memory());
  final vocabulary = TestVocabularyRepository();
  final content = (await vocabulary.loadLocal(JlptLevel.n2)).content;
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      vocabularyRepositoryProvider.overrideWithValue(vocabulary),
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
  return _ChapterHarness(
    router: container.read(appRouterProvider),
    catalog: StudyCatalog(content, const {}, const {}),
    progress: container.read(progressRepositoryProvider),
  );
}
