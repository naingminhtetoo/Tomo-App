import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/app.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/router/app_router.dart';
import 'package:tomo/core/database/app_database.dart';
import 'package:tomo/features/level_selection/data/app_preferences.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/level_selection/presentation/level_catalog_controller.dart';
import 'package:tomo/features/progress/presentation/progress_providers.dart';
import 'package:tomo/features/vocabulary/presentation/word_detail_sheet.dart';
import 'support/test_repositories.dart';

const capture = bool.fromEnvironment('TOMO_CAPTURE_UI');
void main() {
  for (final width in [320.0, 457.0]) {
    testWidgets('local browse, Learn, Review and progress flow at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, capture ? 1600 : 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (capture) {
        final font = FontLoader('NotoSansJP')
          ..addFont(rootBundle.load('assets/fonts/NotoSansJP.ttf'));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      }
      final db = AppDatabase(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          vocabularyRepositoryProvider.overrideWithValue(
            TestVocabularyRepository(),
          ),
          levelCatalogProvider.overrideWith((ref) async => {JlptLevel.n2}),
          preferencesRepositoryProvider.overrideWithValue(
            AppPreferencesRepository(MemoryPreferences()),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: boundaryKey, child: const TomoApp()),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> shot(String name) async {
        expect(tester.takeException(), isNull);
        if (!capture || width != 457) return;
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '${Directory.systemTemp.path}/tomo-ui-screenshots/$name.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> tapText(String text) async {
        final finder = find.text(text).first;
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await shot('home');
      await tapText('Start Learning');
      await shot('study');
      await tapText('Kanji');
      expect(find.text('Choose a learning source'), findsNothing);
      await shot('sources');
      await tapText('Kanji（総まとめ）');
      expect(find.text('Chapter selection'), findsOneWidget);
      await shot('chapters');
      await tapText('Browse Words');
      expect(find.text('禁止'), findsOneWidget);
      expect(find.textContaining('きんし'), findsOneWidget);
      expect(find.textContaining('prohibition'), findsOneWidget);
      expect(
        await container.read(progressRepositoryProvider).loadActiveSession(),
        isNull,
      );
      final id = (await TestVocabularyRepository().loadLocal(
        JlptLevel.n2,
      )).content.vocabulary.keys.first;
      expect(await container.read(wordProgressProvider(id).future), isNull);
      await shot('learning-list');
      await tester.ensureVisible(find.byTooltip('Add favorite').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add favorite').first);
      await tester.pumpAndSettle();
      expect(
        (await container.read(progressRepositoryProvider).findByCardId(id))!
            .favorite,
        isTrue,
      );
      await tapText('禁止');
      expect(find.text('禁止'), findsOneWidget);
      expect(find.text('Example Sentences'), findsNothing);
      await shot('word-detail');
      final router = container.read(appRouterProvider);
      router.pop();
      await tester.pumpAndSettle();
      await tapText('Practice Flashcards');
      expect(find.text('Learn Mode'), findsOneWidget);
      expect(find.text('prohibition'), findsOneWidget);
      expect(find.text('Good'), findsNothing);
      await shot('learn-mode-visible');
      await tapText('Hide Meaning');
      expect(find.text('prohibition'), findsNothing);
      await tapText('Show Meaning');
      final next = find.byKey(const Key('next-card'));
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(
        (await container.read(progressRepositoryProvider).summary())
            .totalReviews,
        0,
      );
      router.go('/home');
      await tester.pumpAndSettle();
      await shot('home-resume');
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('Resume Flashcards'), findsOneWidget);
      await tapText('Continue Learning');
      expect(find.text('Learning List'), findsOneWidget);
      router.go('/home');
      await tester.pumpAndSettle();
      await tapText('Resume Flashcards');
      expect(find.textContaining('2 / '), findsOneWidget);
      expect(find.text('Learn Mode'), findsOneWidget);
      await container.read(progressRepositoryProvider).clearActiveSession();
      container.invalidate(activeSessionProvider);
      router.go('/review');
      await tester.pumpAndSettle();
      await shot('review');
      expect(find.text('0 Words Due Today'), findsOneWidget);
      await tapText('Favorites');
      expect(find.text('禁止'), findsOneWidget);
      expect(find.text('Review Mode'), findsOneWidget);
      expect(find.text('prohibition'), findsNothing);
      await tapText('Reveal Meaning');
      expect(find.text('prohibition'), findsOneWidget);
      await tapText('Good');
      expect(
        (await container.read(progressRepositoryProvider).summary()).learned,
        1,
      );
      router.go('/progress');
      await tester.pumpAndSettle();
      expect(find.text('Your Progress'), findsOneWidget);
      final sourceGroup = find.text('N2 / Kanji / Kanji（総まとめ）');
      await tester.ensureVisible(sourceGroup);
      await tester.tap(sourceGroup);
      await tester.pumpAndSettle();
      await tapText('第１週');
      expect(find.text('Learning List'), findsOneWidget);
      router.go('/progress');
      await tester.pumpAndSettle();
      await shot('progress');
      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.text('Study preferences'), findsOneWidget);
      await shot('settings');
      router.go('/study/n2/category/grammar');
      await tester.pumpAndSettle();
      expect(find.text('No grammar content installed yet.'), findsOneWidget);
      router.go('/study/n2/review/due');
      await tester.pumpAndSettle();
      expect(find.text('No words in this collection yet.'), findsOneWidget);
      await shot('empty-review');
      router.go('/study/n2');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('local-search')), '禁止');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '禁止'));
      await tester.pumpAndSettle();
      expect(find.byType(WordDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(await container.read(activeSessionProvider.future), isNull);
    });
  }
}
