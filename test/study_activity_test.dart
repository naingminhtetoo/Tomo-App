import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/database/app_database.dart';
import 'package:tomo/features/progress/data/drift_progress_repository.dart';
import 'package:tomo/features/progress/domain/progress_repository.dart';

void main() {
  test(
    'weekly activity uses review history, calendar days, level IDs and consecutive streak',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      var clock = DateTime.utc(2026, 10, 1, 23, 59);
      final repository = DriftProgressRepository(db, clock: () => clock);
      addTearDown(() async {
        await repository.close();
        await db.close();
      });
      await repository.recordReview(
        'n2',
        ReviewRating.easy,
      ); // outside seven days
      clock = DateTime.utc(2026, 10, 4, 12);
      await repository.recordReview(
        'n2',
        ReviewRating.again,
      ); // isolated earlier day
      clock = DateTime.utc(2026, 10, 6, 23, 59);
      await repository.recordReview('n2', ReviewRating.good);
      clock = DateTime.utc(2026, 10, 7, 0, 1);
      await repository.recordReview('n2', ReviewRating.hard);
      await repository.recordReview('n2', ReviewRating.again);
      clock = DateTime.utc(2026, 10, 8, 11);
      await repository.recordReview('other-level', ReviewRating.easy);
      clock = DateTime.utc(2026, 10, 9, 12);
      await repository.recordReview(
        'n2',
        ReviewRating.easy,
      ); // after requested time
      final a = await repository.activity(
        now: DateTime.utc(2026, 10, 8, 12),
        contentIds: {'n2'},
      );
      expect(a.days.first, DateTime.utc(2026, 10, 2));
      expect(a.reviewCounts, [0, 0, 1, 0, 1, 2, 0]);
      expect(a.reviewed, 4);
      expect(a.correct, 2);
      expect(a.accuracy, .5);
      expect(a.streak, 2); // active yesterday: streak still intact today
      clock = DateTime.utc(2026, 10, 8, 12);
      await repository.recordReview('n2', ReviewRating.good);
      expect((await repository.activity(contentIds: {'n2'})).streak, 3);
      expect(
        (await repository.activity(
          now: DateTime.utc(2026, 10, 11),
          contentIds: {'n2'},
        )).streak,
        0,
      );
    },
  );
  test('new-user weekly activity is zero without invented accuracy', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repository = DriftProgressRepository(db);
    addTearDown(() async {
      await repository.close();
      await db.close();
    });
    final a = await repository.activity();
    expect(a.reviewCounts, List.filled(7, 0));
    expect(a.reviewed, 0);
    expect(a.correct, 0);
    expect(a.streak, 0);
  });
}
