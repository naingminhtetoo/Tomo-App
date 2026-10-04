import '../../../level_selection/domain/jlpt_level.dart';
import 'deck_category.dart';
import 'vocabulary_card.dart';

class VocabularyChapter {
  VocabularyChapter({
    required this.id,
    required this.name,
    required List<VocabularyCard> cards,
  }) : cards = List.unmodifiable(cards);
  final String id;
  final String name;
  final List<VocabularyCard> cards;
}

class LevelContent {
  LevelContent({
    required this.level,
    required Map<DeckCategory, List<VocabularyChapter>> categories,
  }) : categories = Map.unmodifiable(
         categories.map(
           (key, value) =>
               MapEntry(key, List<VocabularyChapter>.unmodifiable(value)),
         ),
       );
  final JlptLevel level;
  final Map<DeckCategory, List<VocabularyChapter>> categories;

  List<VocabularyChapter> chapters(DeckCategory category) =>
      categories[category] ?? const [];
  List<VocabularyCard> cards(DeckCategory category, {String? chapterId}) =>
      List.unmodifiable(
        chapters(category)
            .where((chapter) => chapterId == null || chapter.id == chapterId)
            .expand((chapter) => chapter.cards),
      );
}

enum ContentSource { bundled, cache, remote }

class ContentSnapshot {
  const ContentSnapshot({
    required this.content,
    required this.version,
    required this.source,
  });
  final LevelContent content;
  final int version;
  final ContentSource source;
}
