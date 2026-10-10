import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import '../domain/progress_repository.dart';
import '../../settings/presentation/preferences_controller.dart';

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

final favoriteVocabularyIdsProvider =
    FutureProvider.family<Set<String>, JlptLevel>((ref, level) async {
      ref.watch(progressChangesProvider);
      final content = (await ref.watch(
        levelContentProvider(level).future,
      )).content;
      final favorites = await ref
          .watch(progressRepositoryProvider)
          .getFavorites();
      return {
        for (final item in favorites)
          if (item.contentType == ContentType.vocabulary &&
              content.vocabulary.containsKey(item.contentId))
            item.contentId,
      };
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
    this.level,
    this.due,
    this.weak,
    this.favorites,
    this.recent,
    this.mistakes,
  );
  final JlptLevel level;
  final List<StudyProgress> due, weak, favorites, recent, mistakes;
}

final reviewCollectionsProvider = FutureProvider<ReviewCollections>((
  ref,
) async {
  ref.watch(progressChangesProvider);
  final r = ref.watch(progressRepositoryProvider);
  final level = (await ref.watch(preferencesControllerProvider.future)).level;
  final content = (await ref.watch(levelContentProvider(level).future)).content;
  List<StudyProgress> installed(List<StudyProgress> items) => items
      .where(
        (p) =>
            p.contentType == ContentType.vocabulary &&
            content.vocabulary.containsKey(p.contentId),
      )
      .toList();
  return ReviewCollections(
    level,
    installed(await r.getDueItems()),
    installed(await r.getWeakItems()),
    installed(await r.getFavorites()),
    installed(await r.getRecentlyLearned()),
    installed(await r.getCommonMistakes()),
  );
});
