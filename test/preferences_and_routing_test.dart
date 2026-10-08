import 'package:drift/native.dart';
import 'package:tomo/core/database/app_database.dart';
import 'package:tomo/features/progress/domain/progress_repository.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/app.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/router/app_router.dart';
import 'package:tomo/core/storage/preferences_store.dart';
import 'package:tomo/features/level_selection/data/app_preferences.dart';
import 'package:tomo/features/settings/presentation/preferences_controller.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/vocabulary/data/models/legacy_vocabulary_mapper.dart';
import 'package:tomo/features/vocabulary/domain/entities/level_content.dart';
import 'package:tomo/features/vocabulary/domain/repositories/vocabulary_repository.dart';

class TestVocabularyRepository implements VocabularyRepository {
  @override
  Future<ContentSnapshot> loadLocal(JlptLevel level) async => ContentSnapshot(
    content: const LegacyVocabularyMapper().decode(
      File('assets/data/n2.json').readAsStringSync(),
      expectedLevel: level,
    ),
    version: 1,
    source: ContentSource.bundled,
  );
  @override
  Future<ContentSnapshot?> checkForUpdate(
    JlptLevel level, {
    required int currentVersion,
  }) async => null;
}

class MemoryPreferences implements PreferencesStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  test(
    'preferences persist independently from content and reload through a new controller',
    () async {
      final repository = AppPreferencesRepository(MemoryPreferences());
      final first = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(() {
              db.close();
            });
            return db;
          }),
          vocabularyRepositoryProvider.overrideWithValue(
            TestVocabularyRepository(),
          ),
          preferencesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await first.read(preferencesControllerProvider.future);
      await first
          .read(preferencesControllerProvider.notifier)
          .setTheme(ThemeMode.light);
      await first.read(preferencesControllerProvider.notifier).setShuffle(true);
      first.dispose();
      final second = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(() {
              db.close();
            });
            return db;
          }),
          vocabularyRepositoryProvider.overrideWithValue(
            TestVocabularyRepository(),
          ),
          preferencesRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(second.dispose);
      final preferences = await second.read(
        preferencesControllerProvider.future,
      );
      expect(preferences.themeMode, ThemeMode.light);
      expect(preferences.shuffle, isTrue);
    },
  );
  for (final width in [320.0, 1100.0]) {
    testWidgets('startup opens responsive dashboard at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) {
              final db = AppDatabase(NativeDatabase.memory());
              ref.onDispose(() {
                db.close();
              });
              return db;
            }),
            vocabularyRepositoryProvider.overrideWithValue(
              TestVocabularyRepository(),
            ),
            preferencesRepositoryProvider.overrideWithValue(
              AppPreferencesRepository(MemoryPreferences()),
            ),
          ],
          child: const TomoApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Japanese Study Companion'), findsOneWidget);
      expect(find.text('JLPT Level: N2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Open study menu'));
      await tester.pumpAndSettle();
      expect(find.text('1591 cards'), findsOneWidget);
      expect(find.text('134 cards'), findsOneWidget);
      expect(find.text('87 cards'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('invalid route parameters redirect safely to level selection', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase.memory());
          ref.onDispose(() {
            db.close();
          });
          return db;
        }),
        vocabularyRepositoryProvider.overrideWithValue(
          TestVocabularyRepository(),
        ),
        preferencesRepositoryProvider.overrideWithValue(
          AppPreferencesRepository(MemoryPreferences()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TomoApp()),
    );
    await tester.pumpAndSettle();
    final router = container.read(appRouterProvider);
    router.go('/study/not-a-level');
    await tester.pumpAndSettle();
    expect(find.text('JLPT level'), findsOneWidget);
    router.go('/study/n2/deck/not-a-category');
    await tester.pumpAndSettle();
    expect(find.text('JLPT level'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('settings changes the live theme without resetting navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(() {
              db.close();
            });
            return db;
          }),
          vocabularyRepositoryProvider.overrideWithValue(
            TestVocabularyRepository(),
          ),
          preferencesRepositoryProvider.overrideWithValue(
            AppPreferencesRepository(MemoryPreferences()),
          ),
        ],
        child: const TomoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Switch))).brightness,
      Brightness.light,
    );
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'offline study persists review and resume position across navigation',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase(NativeDatabase.memory());
            ref.onDispose(() {
              db.close();
            });
            return db;
          }),
          vocabularyRepositoryProvider.overrideWithValue(
            TestVocabularyRepository(),
          ),
          preferencesRepositoryProvider.overrideWithValue(
            AppPreferencesRepository(MemoryPreferences()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TomoApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reviewed today'), findsOneWidget);
      final router = container.read(appRouterProvider);
      router.go('/study/n2/deck/kanji');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start studying'));
      await tester.pumpAndSettle();
      expect(find.text('禁止'), findsOneWidget);
      await tester.tap(find.text('Tap to reveal'));
      await tester.pumpAndSettle();
      expect(find.text('prohibition'), findsOneWidget);
      await tester.tap(find.text('good'));
      await tester.pumpAndSettle();
      final repository = container.read(progressRepositoryProvider);
      final active = (await repository.loadActiveSession())!;
      expect(active.currentIndex, 1);
      expect(
        (await repository.findByCardId(active.contentIds.first))!.correctCount,
        1,
      );
      expect(
        (await repository.getReviewHistory(
          active.contentIds.first,
        )).single.rating,
        ReviewRating.good,
      );
      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Resume · card 2'), findsOneWidget);
      await tester.tap(find.text('Resume · card 2'));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 / '), findsOneWidget);
      expect(find.text('Tap to reveal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
