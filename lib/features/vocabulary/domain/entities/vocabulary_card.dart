import '../../../level_selection/domain/jlpt_level.dart';
import 'deck_category.dart';

/// Static content only. User review data is stored separately by card ID.
class VocabularyCard {
  VocabularyCard({
    required this.id,
    required this.word,
    required this.reading,
    required List<String> meanings,
    required this.level,
    required this.category,
    required this.chapter,
    this.exampleSentence,
    this.exampleTranslation,
    List<String> tags = const [],
    this.difficulty,
  }) : meanings = List.unmodifiable(meanings),
       tags = List.unmodifiable(tags);

  final String id;
  final String word;
  final String reading;
  final List<String> meanings;
  final JlptLevel level;
  final DeckCategory category;
  final String chapter;
  final String? exampleSentence;
  final String? exampleTranslation;
  final List<String> tags;
  final int? difficulty;
}
