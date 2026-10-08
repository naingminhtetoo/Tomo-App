import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/core/storage/content_cache.dart';
import 'package:tomo/core/storage/file_content_cache.dart';
import 'package:tomo/features/flashcards/presentation/study_controller.dart';
import 'package:tomo/features/level_selection/data/app_preferences.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/progress/domain/progress_repository.dart';
import 'package:tomo/features/vocabulary/domain/entities/deck_category.dart';
import 'package:tomo/features/vocabulary/domain/entities/level_content.dart';
import 'package:tomo/features/vocabulary/presentation/vocabulary_controller.dart';
import 'support/test_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'production asset/cache and background SQLite providers preserve study across restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tomo-production-audit-',
      );
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => directory.path,
      );
      addTearDown(() async {
        messenger.setMockMethodCallHandler(channel, null);
        await directory.delete(recursive: true);
      });
      ProviderContainer open() => ProviderContainer(
        overrides: [
          // Only the platform settings boundary is replaced. Content and progress
          // are the default production providers, including asset loading and files.
          preferencesRepositoryProvider.overrideWithValue(
            AppPreferencesRepository(MemoryPreferences()),
          ),
        ],
      );
      final first = open();
      final database = first.read(appDatabaseProvider);
      late String cardId;
      late ActiveStudySession saved;
      try {
        final request = studyRequest(
          level: JlptLevel.n2,
          category: DeckCategory.kanji,
          autoStart: true,
        );
        first.listen(studyControllerProvider(request), (_, _) {});
        final initial = await first.read(
          studyControllerProvider(request).future,
        );
        expect(initial.content.vocabulary.length, 1747);
        expect(initial.card!.word, '禁止');
        cardId = initial.card!.id;
        final controller = first.read(
          studyControllerProvider(request).notifier,
        );
        await controller.toggleFavorite();
        await controller.toggleDifficult();
        controller.flip();
        await controller.rate(ReviewRating.good);
        saved = (await first
            .read(progressRepositoryProvider)
            .loadActiveSession())!;
        expect(saved.currentIndex, 1);
        // Exercise the real file envelope, not a cache implementation test double.
        await FileContentCache().write(
          'n2',
          CachedContent(
            version: 2,
            json: (await rootBundle.loadString('assets/data/n2.json')),
          ),
        );
      } finally {
        first.dispose();
        await database.close();
      }
      expect(await File('${directory.path}/tomo.sqlite').exists(), isTrue);
      expect(
        await File('${directory.path}/tomo_content/n2.json').exists(),
        isTrue,
      );
      final second = open();
      final reopenedDatabase = second.read(appDatabaseProvider);
      try {
        final content = await second.read(
          levelContentProvider(JlptLevel.n2).future,
        );
        expect(content.source, ContentSource.cache);
        expect(content.version, 2);
        final request = studyRequest(level: JlptLevel.n2, resume: true);
        second.listen(studyControllerProvider(request), (_, _) {});
        final resumed = await second.read(
          studyControllerProvider(request).future,
        );
        expect(resumed.ids, saved.contentIds);
        expect(resumed.index, 1);
        final repository = second.read(progressRepositoryProvider);
        final flags = (await repository.findByCardId(cardId))!;
        expect(flags.favorite, isTrue);
        expect(flags.difficult, isTrue);
        expect(flags.correctCount, 1);
        expect(
          (await repository.getReviewHistory(cardId)).single.rating,
          ReviewRating.good,
        );
      } finally {
        second.dispose();
        await reopenedDatabase.close();
      }
    },
  );
}
