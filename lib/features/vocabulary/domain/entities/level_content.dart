import '../../../level_selection/domain/jlpt_level.dart';
import '../../../kanji/domain/kanji_content.dart';
import '../../../grammar/domain/grammar_content.dart';
import 'study_deck.dart';
import 'deck_category.dart';
import 'vocabulary_card.dart';

class VocabularyChapter {
  VocabularyChapter({
    required this.id,
    required this.name,
    required List<VocabularyCard> cards,
  }) : cards = List.unmodifiable(cards);
  final String id, name;
  final List<VocabularyCard> cards;
}

class LevelContent {
  LevelContent({
    required this.level,
    required Map<DeckCategory, List<VocabularyChapter>> categories,
    Map<String, VocabularyCard>? vocabulary,
    List<StudyDeck> decks = const [],
    List<KanjiContent> kanji = const [],
    List<GrammarContent> grammar = const [],
  }) : categories = Map.unmodifiable(
         categories.map(
           (k, v) => MapEntry(k, List<VocabularyChapter>.unmodifiable(v)),
         ),
       ),
       vocabulary = Map.unmodifiable(
         vocabulary ??
             {
               for (final cs in categories.values)
                 for (final c in cs)
                   for (final card in c.cards) card.id: card,
             },
       ),
       decks = List.unmodifiable(decks),
       kanji = List.unmodifiable(kanji),
       grammar = List.unmodifiable(grammar);
  final JlptLevel level;
  final Map<DeckCategory, List<VocabularyChapter>> categories;
  final Map<String, VocabularyCard> vocabulary;
  final List<StudyDeck> decks;
  final List<KanjiContent> kanji;
  final List<GrammarContent> grammar;
  List<VocabularyChapter> chapters(DeckCategory category) =>
      categories[category] ?? const [];
  List<VocabularyCard> cards(DeckCategory category, {String? chapterId}) =>
      List.unmodifiable(
        chapters(category)
            .where((c) => chapterId == null || c.id == chapterId)
            .expand((c) => c.cards),
      );
  List<VocabularyCard> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return List.unmodifiable(
      vocabulary.values.where(
        (c) => [
          c.word,
          c.reading,
          c.romaji ?? '',
          ...c.meanings,
        ].any((v) => v.toLowerCase().contains(q)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'level': level.label,
    'vocabulary': vocabulary.values.map((c) => c.toJson()).toList(),
    'decks': decks.map((d) => d.toJson()).toList(),
    'kanji': kanji.map((k) => k.toJson()).toList(),
    'grammar': grammar.map((g) => g.toJson()).toList(),
  };
}

enum ContentSource { bundled, cache, remote }

class ContentSnapshot {
  const ContentSnapshot({
    required this.content,
    required this.version,
    required this.source,
    this.fileVersions = const {},
  });
  final LevelContent content;
  final int version;
  final ContentSource source;
  final Map<String, int> fileVersions;
}
