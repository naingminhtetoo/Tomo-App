import '../../vocabulary/domain/entities/level_content.dart';
import '../../vocabulary/domain/entities/study_deck.dart';
import '../../vocabulary/domain/entities/deck_category.dart';
import '../../progress/domain/progress_repository.dart';

enum StudyCategory {
  vocabulary('Vocabulary', '語彙'),
  kanji('Kanji', '漢字'),
  grammar('Grammar', '文法'),
  adverbs('Adverbs', '副詞');

  const StudyCategory(this.label, this.japanese);
  final String label, japanese;
  static StudyCategory? tryParse(String? key) =>
      values.where((c) => c.name == key).firstOrNull;
}

class StudySource {
  StudySource({
    required this.id,
    required this.title,
    required List<StudyDeck> decks,
  }) : decks = List.unmodifiable(decks);
  final String id, title;
  final List<StudyDeck> decks;
  Set<String> get contentIds => decks.expand((d) => d.contentIds).toSet();
}

class StudyCatalog {
  StudyCatalog(
    this.content,
    this.categoryProgress,
    this.chapterProgress, [
    this.sourceProgress = const {},
  ]);
  final LevelContent content;
  final Map<StudyCategory, DeckProgress> categoryProgress;
  final Map<String, DeckProgress> chapterProgress;
  final Map<String, DeckProgress> sourceProgress;
  List<StudyDeck> decks(StudyCategory category) => content.decks
      .where(
        (d) => switch (category) {
          StudyCategory.vocabulary =>
            d.category != 'adverbs' &&
                d.contentIds.any(content.vocabulary.containsKey),
          StudyCategory.kanji => ['kanji', 'kanji_master'].contains(d.category),
          StudyCategory.grammar =>
            d.category == 'grammar' &&
                d.contentIds.any(
                  (id) => content.grammar.any((g) => g.id == id),
                ),
          StudyCategory.adverbs =>
            ['adverbs', 'adverb'].contains(d.category) &&
                d.contentIds.any(content.vocabulary.containsKey),
        },
      )
      .toList();
  List<StudySource> sources(StudyCategory category) {
    final groups = <String, List<StudyDeck>>{};
    for (final d in decks(category)) {
      (groups[d.source ?? d.category] ??= []).add(d);
    }
    return groups.entries
        .map(
          (e) =>
              StudySource(id: e.key, title: sourceTitle(e.key), decks: e.value),
        )
        .toList();
  }

  Set<String> ids(StudyCategory category) => decks(category)
      .expand((d) => d.contentIds)
      .where(
        (id) =>
            content.vocabulary.containsKey(id) ||
            content.grammar.any((g) => g.id == id) ||
            content.kanji.any((k) => k.id == id),
      )
      .toSet();
  static String sourceTitle(String id) =>
      DeckCategory.tryParse(id)?.label ?? id;
  static StudyCategory categoryForDeck(StudyDeck deck) =>
      switch (DeckCategory.tryParse(deck.category) ?? DeckCategory.other) {
        DeckCategory.kanji || DeckCategory.kanjiMaster => StudyCategory.kanji,
        DeckCategory.vocabularyShinkanzen ||
        DeckCategory.vocabularySoumatome => StudyCategory.vocabulary,
        DeckCategory.adverb => StudyCategory.adverbs,
        DeckCategory.other =>
          deck.category == 'grammar'
              ? StudyCategory.grammar
              : StudyCategory.vocabulary,
      };
  static String deckTitle(StudyDeck deck) => deck.title.trim().isEmpty
      ? 'All ${sourceTitle(deck.source ?? deck.category)}'
      : deck.title;
}
