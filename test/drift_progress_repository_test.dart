import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/database/app_database.dart';
import 'package:tomo/features/progress/data/drift_progress_repository.dart';
import 'package:tomo/features/progress/domain/progress_repository.dart';

void main() {
  late AppDatabase db;
  late DriftProgressRepository repository;
  final now = DateTime(2026, 10, 8, 12);
  group('in-memory user state', () {
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repository = DriftProgressRepository(db, clock: () => now);
    });
    tearDown(() async {
      await repository.close();
      await db.close();
    });
    test('schema v1 stores user state and no learning content', () async {
      expect(db.schemaVersion, 1);
      await repository.toggleFavorite('word');
      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      expect(
        tables.map((r) => r.read<String>('name')),
        containsAll([
          'study_progress',
          'review_history',
          'study_sessions',
          'active_session',
        ]),
      );
      final columns = await db
          .customSelect('PRAGMA table_info(study_progress)')
          .get();
      expect(
        columns.map((r) => r.read<String>('name')),
        isNot(contains('word')),
      );
      expect(
        columns.map((r) => r.read<String>('name')),
        isNot(contains('meaning')),
      );
    });
    test('favorites and difficult flags do not erase review state', () async {
      await repository.recordReview(
        'word',
        ReviewRating.good,
        newInterval: 3,
        nextReviewAt: now.add(const Duration(days: 3)),
      );
      expect(await repository.toggleFavorite('word'), isTrue);
      expect(await repository.toggleDifficult('word'), isTrue);
      final state = (await repository.findByCardId('word'))!;
      expect(state.correctCount, 1);
      expect(state.reviewInterval, 3);
      expect(state.syncStatus, 'pending');
      expect((await repository.getFavorites()).single.contentId, 'word');
      expect((await repository.getDifficultItems()).single.contentId, 'word');
      expect(await repository.toggleFavorite('word'), isFalse);
      expect(await repository.getFavorites(), isEmpty);
      await repository.recordReview('word', ReviewRating.good);
      expect(
        (await repository.findByCardId('word'))!.nextReviewAt,
        now.add(const Duration(days: 3)),
      );
    });
    test(
      'review history, due, weak and summary are calculated from real state',
      () async {
        await repository.recordReview(
          'word',
          ReviewRating.again,
          newInterval: 1,
          nextReviewAt: now,
          responseTimeMs: 900,
        );
        await repository.recordReview(
          'word',
          ReviewRating.hard,
          newInterval: 2,
          nextReviewAt: now,
        );
        await repository.recordReview(
          'future',
          ReviewRating.easy,
          nextReviewAt: now.add(const Duration(days: 1)),
        );
        final history = await repository.getReviewHistory('word');
        expect(history.length, 2);
        expect(history.last.previousInterval, 1);
        expect(history.last.newInterval, 2);
        expect(history.first.responseTimeMs, 900);
        expect((await repository.getDueItems()).single.contentId, 'word');
        expect((await repository.getWeakItems()).single.contentId, 'word');
        expect((await repository.getCommonMistakes()).single.contentId, 'word');
        expect((await repository.getRecentlyLearned()).length, 2);
        final summary = await repository.summary(
          contentIds: {'word'},
          now: now,
        );
        expect(summary.reviewedToday, 2);
        expect(summary.learnedToday, 1);
        expect(summary.accuracy, 0.5);
        expect(summary.dueCount, 1);
        final chapter = await repository.deckProgress([
          'word',
          'unlearned',
          'word',
        ]);
        expect(chapter.learned, 1);
        expect(chapter.total, 2);
        expect(chapter.fraction, 0.5);
        expect((await repository.deckProgress([])).fraction, 0);
      },
    );
    test(
      'review, session counters and resume index advance atomically',
      () async {
        final session = ActiveStudySession(
          sessionId: 'session',
          deckId: 'deck',
          level: 'n2',
          currentIndex: 0,
          studyMode: 'flashcards',
          shuffleEnabled: true,
          startedAt: now,
          updatedAt: now,
          contentIds: ['b', 'a'],
        );
        await repository.saveActiveSession(session);
        await repository.recordReview(
          'b',
          ReviewRating.good,
          sessionId: 'session',
          advanceActiveSession: true,
        );
        expect((await repository.loadActiveSession())!.currentIndex, 1);
        expect((await repository.loadActiveSession())!.contentIds, ['b', 'a']);
        await expectLater(
          repository.recordReview(
            'b',
            ReviewRating.good,
            sessionId: 'session',
            advanceActiveSession: true,
          ),
          throwsStateError,
        );
        expect((await repository.getReviewHistory('b')).length, 1);
        await repository.recordReview(
          'a',
          ReviewRating.again,
          sessionId: 'session',
          advanceActiveSession: true,
        );
        expect(await repository.loadActiveSession(), isNull);
        final completed = (await repository.getStudySessions()).single;
        expect(completed.endedAt, now);
        expect(completed.reviewedCount, 2);
        expect(completed.correctCount, 1);
        await expectLater(
          repository.saveActiveSession(session),
          throwsStateError,
        );
      },
    );
    test('invalid review rolls back all user state changes', () async {
      await expectLater(
        repository.recordReview(
          'word',
          ReviewRating.good,
          sessionId: 'missing',
        ),
        throwsStateError,
      );
      expect(await repository.findByCardId('word'), isNull);
      expect(await repository.getReviewHistory('word'), isEmpty);
    });
    test('clear and complete session retain historical records', () async {
      for (final id in ['cleared', 'completed']) {
        await repository.saveActiveSession(
          ActiveStudySession(
            sessionId: id,
            deckId: 'deck',
            level: 'n2',
            currentIndex: 0,
            studyMode: 'flashcards',
            shuffleEnabled: false,
            startedAt: now,
            updatedAt: now,
            contentIds: ['word'],
          ),
        );
        if (id == 'cleared') {
          await repository.clearActiveSession();
        } else {
          await repository.completeActiveSession();
        }
      }
      expect(await repository.loadActiveSession(), isNull);
      expect((await repository.getStudySessions()).length, 2);
    });
  });
  test(
    'file database preserves flags, history and active order across reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp('tomo-db-');
      final file = File('${directory.path}/tomo.sqlite');
      Future<DriftProgressRepository> open() async => DriftProgressRepository(
        AppDatabase(NativeDatabase(file)),
        clock: () => now,
      );
      final first = await open();
      await first.toggleFavorite('word');
      await first.toggleDifficult('word');
      await first.recordReview('word', ReviewRating.good);
      await first.saveActiveSession(
        ActiveStudySession(
          sessionId: 's',
          deckId: 'd',
          level: 'n2',
          currentIndex: 1,
          studyMode: 'flashcards',
          shuffleEnabled: true,
          startedAt: now,
          updatedAt: now,
          contentIds: ['other', 'word'],
        ),
      );
      await first.close();
      await first.database.close();
      final second = await open();
      try {
        expect((await second.findByCardId('word'))!.favorite, isTrue);
        expect((await second.findByCardId('word'))!.difficult, isTrue);
        expect((await second.getReviewHistory('word')).length, 1);
        expect((await second.loadActiveSession())!.currentIndex, 1);
        expect((await second.loadActiveSession())!.contentIds, [
          'other',
          'word',
        ]);
      } finally {
        await second.close();
        await second.database.close();
        await directory.delete(recursive: true);
      }
    },
  );
  test('unsupported schema versions fail without deleting user data', () async {
    final directory = await Directory.systemTemp.createTemp('tomo-migration-');
    final file = File('${directory.path}/tomo.sqlite');
    final connection = sqlite.sqlite3.open(file.path);
    connection.execute('CREATE TABLE preserved_user_data (value TEXT)');
    connection.execute(
      "INSERT INTO preserved_user_data VALUES ('valuable history')",
    );
    connection.execute('PRAGMA user_version = 2');
    connection.dispose();
    final database = AppDatabase(NativeDatabase(file));
    try {
      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsStateError,
      );
    } finally {
      await database.close();
    }
    final reopened = sqlite.sqlite3.open(file.path);
    try {
      expect(
        reopened
            .select('SELECT value FROM preserved_user_data')
            .single['value'],
        'valuable history',
      );
      expect(reopened.select('PRAGMA user_version').single['user_version'], 2);
    } finally {
      reopened.dispose();
      await directory.delete(recursive: true);
    }
  });
}
