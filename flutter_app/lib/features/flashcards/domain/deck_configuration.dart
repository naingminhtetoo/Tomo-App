import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/domain/entities/deck_category.dart';

/// Session configuration; the flashcard engine is introduced in Phase 4.
class DeckConfiguration {
  const DeckConfiguration({required this.level, required this.category, this.chapterId, this.shuffle = false});
  final JlptLevel level;
  final DeckCategory category;
  final String? chapterId;
  final bool shuffle;
}
