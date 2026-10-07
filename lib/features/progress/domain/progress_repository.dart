/// Future database boundary. Never store review history in content JSON or preferences.
abstract interface class ProgressRepository {
  Future<ReviewProgress?> findByCardId(String cardId);
  Future<void> save(ReviewProgress progress);
}

class ReviewProgress {
  const ReviewProgress({
    required this.cardId,
    required this.reviewCount,
    this.lastReviewedAt,
  });
  final String cardId;
  final int reviewCount;
  final DateTime? lastReviewedAt;
}
