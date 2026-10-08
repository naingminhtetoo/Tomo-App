import '../../../level_selection/domain/jlpt_level.dart';
import 'deck_category.dart';
import 'content_example.dart';

/// Shared content only; preferences, mastery and review counts live in SQLite.
class VocabularyCard {
  VocabularyCard({
    required this.id,
    required this.word,
    required this.reading,
    required List<String> meanings,
    required this.level,
    this.category = DeckCategory.other,
    this.chapter = '',
    this.romaji,
    this.exampleSentence,
    this.exampleTranslation,
    this.difficulty,
    List<String> tags = const [],
    List<String> partOfSpeech = const [],
    List<String> kanjiIds = const [],
    List<ContentExample> examples = const [],
    List<String> collocations = const [],
  }) : meanings = List.unmodifiable(meanings),
       tags = List.unmodifiable(tags),
       partOfSpeech = List.unmodifiable(partOfSpeech),
       kanjiIds = List.unmodifiable(kanjiIds),
       examples = List.unmodifiable(examples),
       collocations = List.unmodifiable(collocations);
  final String id, word, reading;
  final String? romaji;
  final List<String> meanings, tags, partOfSpeech, kanjiIds, collocations;
  final List<ContentExample> examples;
  final JlptLevel level;
  // Compatibility metadata only: membership is represented by StudyDeck.
  final DeckCategory category;
  final String chapter;
  final String? exampleSentence, exampleTranslation;
  final int? difficulty;
  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'reading': reading,
    'level': level.label,
    'meanings': meanings,
    'partOfSpeech': partOfSpeech,
    'kanjiIds': kanjiIds,
    'examples': examples.map((e) => e.toJson()).toList(),
    'collocations': collocations,
    'tags': tags,
    if (romaji != null) 'romaji': romaji,
    if (exampleSentence != null) 'exampleSentence': exampleSentence,
    if (exampleTranslation != null) 'exampleTranslation': exampleTranslation,
    if (difficulty != null) 'difficulty': difficulty,
  };
}
