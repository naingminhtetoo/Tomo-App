import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import '../domain/progress_repository.dart';

final progressChangesProvider = StreamProvider<int>((ref) async* {
  final repository = ref.watch(progressRepositoryProvider);
  var revision = 0;
  yield revision;
  await for (final _ in repository.changes) {
    yield ++revision;
  }
});
final activeSessionProvider = FutureProvider<ActiveStudySession?>((ref) {
  ref.watch(progressChangesProvider);
  return ref.watch(progressRepositoryProvider).loadActiveSession();
});
final progressSummaryProvider =
    FutureProvider.family<ProgressSummaryData, JlptLevel>((ref, level) async {
      ref.watch(progressChangesProvider);
      final snapshot = await ref.watch(levelContentProvider(level).future);
      final content = snapshot.content;
      return ref
          .watch(progressRepositoryProvider)
          .summary(
            contentIds: {
              ...content.vocabulary.keys,
              ...content.kanji.map((k) => k.id),
              ...content.grammar.map((g) => g.id),
            },
          );
    });
final chapterProgressProvider =
    FutureProvider.family<DeckProgress, ({JlptLevel level, String deckId})>((
      ref,
      key,
    ) async {
      ref.watch(progressChangesProvider);
      final snapshot = await ref.watch(levelContentProvider(key.level).future);
      final decks = snapshot.content.decks.where((d) => d.id == key.deckId);
      return ref
          .watch(progressRepositoryProvider)
          .deckProgress(decks.isEmpty ? const [] : decks.single.contentIds);
    });

class ReviewCollections {
  const ReviewCollections(
    this.due,
    this.weak,
    this.favorites,
    this.recent,
    this.mistakes,
  );
  final List<StudyProgress> due, weak, favorites, recent, mistakes;
}

final reviewCollectionsProvider = FutureProvider<ReviewCollections>((
  ref,
) async {
  ref.watch(progressChangesProvider);
  final r = ref.watch(progressRepositoryProvider);
  return ReviewCollections(
    await r.getDueItems(),
    await r.getWeakItems(),
    await r.getFavorites(),
    await r.getRecentlyLearned(),
    await r.getCommonMistakes(),
  );
});
