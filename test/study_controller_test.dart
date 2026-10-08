import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/core/database/app_database.dart';
import 'package:tomo/features/flashcards/presentation/study_controller.dart';
import 'package:tomo/features/level_selection/data/app_preferences.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/progress/data/drift_progress_repository.dart';
import 'package:tomo/features/progress/domain/progress_repository.dart';
import 'package:tomo/features/progress/presentation/progress_providers.dart';
import 'package:tomo/features/study_menu/domain/study_catalog.dart';
import 'package:tomo/features/study_menu/presentation/catalog_provider.dart';
import 'package:tomo/features/vocabulary/domain/entities/deck_category.dart';
import 'support/test_repositories.dart';

void main() {
  late AppDatabase db;
  late DriftProgressRepository repository;
  late ProviderContainer container;
  final request = studyRequest(
    level: JlptLevel.n2,
    category: DeckCategory.kanji,
    autoStart: true,
  );
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftProgressRepository(db);
    container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(repository),
        vocabularyRepositoryProvider.overrideWithValue(
          TestVocabularyRepository(),
        ),
        preferencesRepositoryProvider.overrideWithValue(
          AppPreferencesRepository(MemoryPreferences()),
        ),
        studyRandomProvider.overrideWithValue(Random(42)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await repository.close();
    await db.close();
  });
  Future<StudyView> load(StudyRequest key) async {
    final provider = studyControllerProvider(key);
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  StudyController controller(StudyRequest key) =>
      container.read(studyControllerProvider(key).notifier);
  StudyView view(StudyRequest key) =>
      container.read(studyControllerProvider(key)).requireValue;

  test(
    'flip, previous and next preserve canonical order and do not record reviews',
    () async {
      final initial = await load(request);
      expect(initial.card!.word, '禁止');
      expect(initial.ids, initial.baselineIds);
      controller(request).flip();
      expect(view(request).flipped, isTrue);
      await controller(request).move(1);
      expect(view(request).index, 1);
      expect(view(request).flipped, isFalse);
      await controller(request).move(-1);
      await controller(request).move(-1);
      expect(view(request).index, 0);
      expect(view(request).ids, initial.ids);
      expect((await repository.summary()).totalReviews, 0);
      expect((await repository.loadActiveSession())!.currentIndex, 0);
      await expectLater(
        controller(request).rate(ReviewRating.good),
        throwsStateError,
      );
    },
  );
  test(
    'explicit shuffle persists permutation and restores canonical order',
    () async {
      final original = await load(request);
      await controller(request).move(3);
      await controller(request).setShuffle(true);
      final shuffled = view(request);
      expect(shuffled.ids.toSet(), original.ids.toSet());
      expect(shuffled.ids, isNot(original.ids));
      expect(shuffled.index, 0);
      await controller(request).move(2);
      final saved = (await repository.loadActiveSession())!;
      final resumedRequest = studyRequest(level: JlptLevel.n2, resume: true);
      final resumed = await load(resumedRequest);
      expect(resumed.ids, saved.contentIds);
      expect(resumed.index, 2);
      expect(resumed.shuffle, isTrue);
      await controller(resumedRequest).setShuffle(false);
      expect(view(resumedRequest).ids, original.ids);
      expect(view(resumedRequest).index, 0);
    },
  );
  test(
    'flags, chapter progress and recent reviews share persisted state',
    () async {
      final initial = await load(request);
      final id = initial.card!.id;
      await controller(request).toggleFavorite();
      await controller(request).toggleDifficult();
      controller(request).flip();
      await controller(request).rate(ReviewRating.again);
      final p = (await repository.findByCardId(id))!;
      expect(p.favorite, isTrue);
      expect(p.difficult, isTrue);
      expect(p.incorrectCount, 1);
      expect(
        (await repository.getReviewHistory(id)).single.rating,
        ReviewRating.again,
      );
      expect((await repository.loadActiveSession())!.currentIndex, 1);
      final catalog = await container.read(
        studyCatalogProvider(JlptLevel.n2).future,
      );
      expect(catalog.chapterProgress[initial.deckId]!.learned, 1);
      expect(catalog.categoryProgress[StudyCategory.kanji]!.learned, 1);
      expect((await repository.getRecentlyLearned()).single.contentId, id);
      expect((await repository.getWeakItems()).single.contentId, id);
      expect((await repository.getCommonMistakes()).single.contentId, id);
    },
  );
  test('single word practice completes and retains review history', () async {
    final content = (await TestVocabularyRepository().loadLocal(
      JlptLevel.n2,
    )).content;
    final key = studyRequest(
      level: JlptLevel.n2,
      contentId: content.vocabulary.keys.first,
      autoStart: true,
    );
    await load(key);
    controller(key).flip();
    await controller(key).rate(ReviewRating.easy);
    expect(view(key).completed, isTrue);
    expect(view(key).card, isNull);
    expect(await repository.loadActiveSession(), isNull);
    expect((await repository.getStudySessions()).single.reviewedCount, 1);
  });
  test('empty and missing content create no session', () async {
    for (final key in [
      studyRequest(level: JlptLevel.n2, reviewFilter: 'due', autoStart: true),
      studyRequest(
        level: JlptLevel.n2,
        contentId: 'not-installed',
        autoStart: true,
      ),
    ]) {
      final result = await load(key);
      expect(result.ids, isEmpty);
      expect(result.card, isNull);
      expect(result.active, isNull);
    }
    expect(await repository.loadActiveSession(), isNull);
  });
  test('new collection cannot silently replace unfinished session', () async {
    final first = await load(request);
    final second = studyRequest(
      level: JlptLevel.n2,
      contentId: first.ids.last,
      autoStart: true,
    );
    final conflict = await load(second);
    expect(conflict.active, isNull);
    expect(conflict.conflict!.sessionId, first.active!.sessionId);
    await expectLater(controller(second).start(), throwsStateError);
    expect(
      (await repository.loadActiveSession())!.sessionId,
      first.active!.sessionId,
    );
    await controller(second).start(replaceCurrent: true);
    expect(
      (await repository.loadActiveSession())!.deckId,
      'word:${first.ids.last}',
    );
  });
  test(
    'review collections exclude stale IDs and start real saved words',
    () async {
      final content = (await TestVocabularyRepository().loadLocal(
        JlptLevel.n2,
      )).content;
      final id = content.vocabulary.keys.first;
      await repository.toggleFavorite('uninstalled');
      await repository.toggleFavorite(id);
      await repository.recordReview(
        id,
        ReviewRating.again,
        nextReviewAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final collections = await container.read(
        reviewCollectionsProvider.future,
      );
      expect(collections.favorites.map((p) => p.contentId), [id]);
      expect(collections.due.map((p) => p.contentId), [id]);
      final key = studyRequest(
        level: JlptLevel.n2,
        reviewFilter: 'favorites',
        autoStart: true,
      );
      final result = await load(key);
      expect(result.ids, [id]);
      expect(result.active!.studyMode, 'review');
      await repository.toggleFavorite(id);
      container.invalidate(studyControllerProvider(key));
      final resumed = await container.read(studyControllerProvider(key).future);
      expect(resumed.ids, [id]);
      await controller(key).setShuffle(true);
      expect(view(key).ids, [id]);
    },
  );
  test(
    'stale controller cannot end a replacement session or reset its position',
    () async {
      final first = await load(request);
      final second = studyRequest(
        level: JlptLevel.n2,
        contentId: first.ids.last,
        autoStart: true,
      );
      await load(second);
      await controller(second).start(replaceCurrent: true);
      final replacement = (await repository.loadActiveSession())!;
      await expectLater(controller(request).end(), throwsStateError);
      expect(
        (await repository.loadActiveSession())!.sessionId,
        replacement.sessionId,
      );
      await container.read(studyControllerProvider(request).future);
      // Ending an unstarted preview also leaves the other session intact.
      await controller(request).end();
      expect(
        (await repository.loadActiveSession())!.sessionId,
        replacement.sessionId,
      );
    },
  );
  test(
    'weak queries include difficult flags and latest Hard without fake failures',
    () async {
      await repository.toggleDifficult('difficult');
      await repository.recordReview('hard', ReviewRating.hard);
      expect(
        (await repository.getWeakItems()).map((p) => p.contentId).toSet(),
        {'difficult', 'hard'},
      );
      expect(await repository.getCommonMistakes(), isEmpty);
      await repository.recordReview('hard', ReviewRating.good);
      expect((await repository.getWeakItems()).single.contentId, 'difficult');
    },
  );
  test(
    'all-chapter resume restores source order when shuffle is turned off',
    () async {
      final key = studyRequest(
        level: JlptLevel.n2,
        category: DeckCategory.kanji,
        source: 'kanji',
        deckId: 'all:kanji',
        autoStart: true,
      );
      final original = await load(key);
      await controller(key).setShuffle(true);
      await controller(key).move(3);
      final saved = (await repository.loadActiveSession())!;
      final resume = studyRequest(level: JlptLevel.n2, resume: true);
      final resumed = await load(resume);
      expect(resumed.ids, saved.contentIds);
      expect(resumed.index, 3);
      await controller(resume).setShuffle(false);
      expect(view(resume).ids, original.ids);
      expect((await repository.loadActiveSession())!.contentIds, original.ids);
    },
  );
  test(
    'review resume restores collection order without changing saved membership',
    () async {
      final content = (await TestVocabularyRepository().loadLocal(
        JlptLevel.n2,
      )).content;
      final ids = content.vocabulary.keys.take(8).toList();
      for (final id in ids) {
        await repository.toggleFavorite(id);
      }
      final key = studyRequest(
        level: JlptLevel.n2,
        reviewFilter: 'favorites',
        autoStart: true,
      );
      final original = await load(key);
      await controller(key).setShuffle(true);
      await controller(key).move(2);
      final saved = (await repository.loadActiveSession())!;
      final resume = studyRequest(level: JlptLevel.n2, resume: true);
      final resumed = await load(resume);
      expect(resumed.ids, saved.contentIds);
      expect(resumed.index, 2);
      await controller(resume).setShuffle(false);
      expect(view(resume).ids, original.ids);
      final added = content.vocabulary.keys.skip(8).first;
      await repository.toggleFavorite(ids.first);
      await repository.toggleFavorite(added);
      container.invalidate(studyControllerProvider(resume));
      await container.read(studyControllerProvider(resume).future);
      await controller(resume).setShuffle(false);
      expect(view(resume).ids.toSet(), ids.toSet());
      expect(view(resume).ids, isNot(contains(added)));
      expect((await repository.loadActiveSession())!.studyMode, 'review');
    },
  );
}
