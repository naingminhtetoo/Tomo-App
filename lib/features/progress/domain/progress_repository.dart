enum ContentType { vocabulary, kanji, grammar }

enum LearningStatus { newItem, learning, mastered }

enum ReviewRating { again, hard, good, easy }

class StudyProgress {
  const StudyProgress({
    required this.contentId,
    this.contentType = ContentType.vocabulary,
    this.status = LearningStatus.newItem,
    this.masteryLevel = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.favorite = false,
    this.difficult = false,
    this.firstLearnedAt,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.reviewInterval = 0,
    this.easeFactor = 2.5,
    required this.updatedAt,
    this.syncStatus = 'pending',
  });
  final String contentId, syncStatus;
  final ContentType contentType;
  final LearningStatus status;
  final int masteryLevel, correctCount, incorrectCount, reviewInterval;
  final bool favorite, difficult;
  final DateTime? firstLearnedAt, lastReviewedAt, nextReviewAt;
  final DateTime updatedAt;
  final double easeFactor;
}

class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.rating,
    required this.reviewedAt,
    required this.previousInterval,
    required this.newInterval,
    this.responseTimeMs,
    this.sessionId,
  });
  final int id, previousInterval, newInterval;
  final String contentId;
  final ContentType contentType;
  final ReviewRating rating;
  final DateTime reviewedAt;
  final int? responseTimeMs;
  final String? sessionId;
}

class StudySession {
  const StudySession({
    required this.id,
    required this.deckId,
    required this.level,
    required this.mode,
    required this.startedAt,
    this.endedAt,
    this.reviewedCount = 0,
    this.correctCount = 0,
  });
  final String id, deckId, level, mode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int reviewedCount, correctCount;
}

class ActiveStudySession {
  ActiveStudySession({
    required this.sessionId,
    required this.deckId,
    required this.level,
    required this.currentIndex,
    required this.studyMode,
    required this.shuffleEnabled,
    required this.startedAt,
    required this.updatedAt,
    required List<String> contentIds,
  }) : contentIds = List.unmodifiable(contentIds);
  final String sessionId, deckId, level, studyMode;
  final int currentIndex;
  final bool shuffleEnabled;
  final DateTime startedAt, updatedAt;
  // Persist actual order so shuffled study resumes at the same item.
  final List<String> contentIds;
}

/// Home uses today's review counts/accuracy; lifetime metrics are explicit
/// so the Progress screen does not reset its totals at midnight.
class ProgressSummaryData {
  const ProgressSummaryData({
    this.reviewedToday = 0,
    this.learnedToday = 0,
    this.learned = 0,
    this.learning = 0,
    this.mastered = 0,
    this.correctReviews = 0,
    this.totalReviews = 0,
    this.dueCount = 0,
    this.lifetimeReviews = 0,
    this.lifetimeCorrectReviews = 0,
  });
  final int reviewedToday,
      learnedToday,
      learned,
      learning,
      mastered,
      correctReviews,
      totalReviews,
      dueCount,
      lifetimeReviews,
      lifetimeCorrectReviews;
  double get accuracy => totalReviews == 0 ? 0 : correctReviews / totalReviews;
  double get lifetimeAccuracy =>
      lifetimeReviews == 0 ? 0 : lifetimeCorrectReviews / lifetimeReviews;
}

class DeckProgress {
  const DeckProgress({required this.learned, required this.total});
  final int learned, total;
  double get fraction => total == 0 ? 0 : learned / total;
}

class StudyActivity {
  StudyActivity({
    required this.days,
    required this.reviewCounts,
    required this.reviewed,
    required this.correct,
    required this.streak,
  }) : assert(days.length == reviewCounts.length);
  final List<DateTime> days;
  final List<int> reviewCounts;
  final int reviewed, correct, streak;
  double get accuracy => reviewed == 0 ? 0 : correct / reviewed;
}

/// The single local-user-data boundary. Content JSON is never written here.
abstract interface class ProgressRepository {
  Stream<void> get changes;
  Future<StudyActivity> activity({DateTime? now, Set<String>? contentIds});
  Future<StudyProgress?> findByCardId(
    String id, {
    ContentType type = ContentType.vocabulary,
  });
  Future<void> save(StudyProgress progress);
  Future<bool> toggleFavorite(
    String id, {
    ContentType type = ContentType.vocabulary,
  });
  Future<bool> toggleDifficult(
    String id, {
    ContentType type = ContentType.vocabulary,
  });
  Future<List<StudyProgress>> getFavorites();
  Future<List<StudyProgress>> getDifficultItems();
  Future<List<StudyProgress>> getDueItems({DateTime? now});
  Future<List<StudyProgress>> getRecentlyLearned();
  Future<List<StudyProgress>> getCommonMistakes();
  Future<List<StudyProgress>> getWeakItems();
  Future<void> recordReview(
    String id,
    ReviewRating rating, {
    ContentType type = ContentType.vocabulary,
    int? newInterval,
    DateTime? nextReviewAt,
    int? responseTimeMs,
    String? sessionId,
    bool advanceActiveSession = false,
  });
  Future<List<ReviewRecord>> getReviewHistory(
    String id, {
    ContentType type = ContentType.vocabulary,
  });
  Future<ProgressSummaryData> summary({Set<String>? contentIds, DateTime? now});
  Future<DeckProgress> deckProgress(
    Iterable<String> contentIds, {
    ContentType type = ContentType.vocabulary,
  });
  Future<void> saveActiveSession(ActiveStudySession session);
  Future<ActiveStudySession?> loadActiveSession();
  Future<void> completeActiveSession();
  Future<void> clearActiveSession();
  Future<List<StudySession>> getStudySessions();
}
