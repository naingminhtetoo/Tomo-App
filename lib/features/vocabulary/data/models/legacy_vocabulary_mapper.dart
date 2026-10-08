import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../../core/errors/content_exception.dart';
import '../../../../core/utils/content_json.dart';
import '../../../level_selection/domain/jlpt_level.dart';
import '../../../kanji/domain/kanji_content.dart';
import '../../../grammar/domain/grammar_content.dart';
import '../../domain/entities/content_example.dart';
import '../../domain/entities/study_deck.dart';
import '../../domain/entities/deck_category.dart';
import '../../domain/entities/level_content.dart';
import '../../domain/entities/vocabulary_card.dart';

/// Compatibility boundary: legacy content is never rewritten. Meanings and
/// array positions are excluded from identity; published IDs always win.
class LegacyVocabularyMapper {
  const LegacyVocabularyMapper();
  static String legacyId(JlptLevel level, String word, String reading) =>
      '${level.name}_vocab_${sha256.convert(utf8.encode(jsonEncode([word.trim(), reading.trim()])))}';

  LevelContent decode(String source, {required JlptLevel expectedLevel}) {
    final root = jsonObject(jsonDecode(source));
    if (JlptLevel.tryParse(jsonText(root['level'])) != expectedLevel) {
      throw const ContentException(
        'Content level does not match the requested level.',
      );
    }
    if (root.containsKey('schemaVersion')) {
      if (root['schemaVersion'] != 1) {
        throw const ContentException('Unsupported content schema.');
      }
      return _canonical(root, expectedLevel);
    }
    final vocabulary = <String, VocabularyCard>{};
    final decks = <StudyDeck>[];
    final explicitIds = <String>{};
    for (final category in DeckCategory.values) {
      final section = root[category.contentKey];
      if (section == null) continue;
      final chapters = jsonList(jsonObject(section)['chapters']);
      for (var ci = 0; ci < chapters.length; ci++) {
        final chapter = jsonObject(chapters[ci]);
        final name = jsonText(chapter['name']);
        final chapterId = '${expectedLevel.name}/${category.contentKey}/$ci';
        final ids = <String>[];
        for (final raw in jsonList(chapter['words'])) {
          final j = jsonObject(raw);
          final card = _card(
            j,
            expectedLevel,
            category: category,
            chapter: name,
            requireId: false,
          );
          if (j['id'] != null && !explicitIds.add(card.id)) {
            throw const ContentException('Duplicate explicit card ID.');
          }
          final previous = vocabulary[card.id];
          if (previous != null) {
            if (previous.word != card.word ||
                previous.reading != card.reading) {
              throw const ContentException('Conflicting card identity.');
            }
            // Multiple legacy sources describe the same word. Keep all supplied meanings.
            vocabulary[card.id] = _card(
              {
                ...previous.toJson(),
                'meanings': {...previous.meanings, ...card.meanings}.toList(),
              },
              expectedLevel,
              category: previous.category,
              chapter: previous.chapter,
            );
          } else {
            vocabulary[card.id] = card;
          }
          ids.add(card.id);
        }
        decks.add(
          StudyDeck(
            id: chapterId,
            title: name,
            level: expectedLevel,
            category: category.contentKey,
            source: category.contentKey,
            chapter: ci + 1,
            contentIds: ids,
          ),
        );
      }
    }
    return _assemble(expectedLevel, vocabulary, decks, const [], const []);
  }

  VocabularyCard _card(
    Map<String, dynamic> j,
    JlptLevel level, {
    DeckCategory category = DeckCategory.other,
    String chapter = '',
    bool requireId = true,
  }) {
    final word = jsonText(j['word'], nonEmpty: true),
        reading = jsonText(j['reading']);
    final id = j['id'] == null && !requireId
        ? legacyId(level, word, reading)
        : jsonText(j['id'], nonEmpty: true);
    if (j['level'] != null &&
        JlptLevel.tryParse(jsonText(j['level'])) != level) {
      throw const ContentException('Wrong card level.');
    }
    final meanings = j['meanings'] == null
        ? [jsonText(j['meaning'])]
        : jsonTexts(j['meanings']);
    if (meanings.isEmpty || meanings.any((m) => m.trim().isEmpty)) {
      throw const ContentException('Card has no meanings.');
    }
    return VocabularyCard(
      id: id,
      word: word,
      reading: reading,
      meanings: meanings,
      level: level,
      category: category,
      chapter: chapter,
      romaji: j['romaji'] as String?,
      partOfSpeech: jsonTexts(j['partOfSpeech']),
      kanjiIds: jsonTexts(j['kanjiIds']),
      examples: (j['examples'] == null ? const [] : jsonList(j['examples']))
          .map((e) => ContentExample.fromJson(jsonObject(e)))
          .toList(),
      collocations: jsonTexts(j['collocations']),
      tags: jsonTexts(j['tags']),
      difficulty: j['difficulty'] as int?,
      exampleSentence: j['exampleSentence'] as String?,
      exampleTranslation: j['exampleTranslation'] as String?,
    );
  }

  LevelContent _canonical(Map<String, dynamic> root, JlptLevel level) {
    final vocabulary = <String, VocabularyCard>{};
    final identityIds = <String, String>{};
    for (final raw in jsonList(root['vocabulary'])) {
      final card = _card(jsonObject(raw), level);
      final identity = legacyId(level, card.word, card.reading);
      if (vocabulary.containsKey(card.id) ||
          identityIds.containsKey(identity)) {
        throw const ContentException('Duplicate master vocabulary.');
      }
      vocabulary[card.id] = card;
      identityIds[identity] = card.id;
    }
    final decks = jsonList(
      root['decks'],
    ).map((j) => StudyDeck.fromJson(jsonObject(j))).toList();
    final kanji = (root['kanji'] == null ? const [] : jsonList(root['kanji']))
        .map((j) => KanjiContent.fromJson(jsonObject(j)))
        .toList();
    final grammar =
        (root['grammar'] == null ? const [] : jsonList(root['grammar']))
            .map((j) => GrammarContent.fromJson(jsonObject(j)))
            .toList();
    final allIds = <String>{...vocabulary.keys};
    for (final k in kanji) {
      if (k.level != level ||
          k.character.runes.length != 1 ||
          (k.strokes != null && k.strokes! < 1) ||
          !allIds.add(k.id)) {
        throw const ContentException('Invalid kanji identity.');
      }
    }
    for (final g in grammar) {
      if (g.level != level || !allIds.add(g.id)) {
        throw const ContentException('Invalid grammar identity.');
      }
    }
    final deckIds = <String>{};
    for (final d in decks) {
      if (d.level != level ||
          !deckIds.add(d.id) ||
          d.contentIds.any((id) => !allIds.contains(id))) {
        throw const ContentException('Invalid deck references.');
      }
    }
    // Vocabulary may reference kanji metadata that is not downloaded yet.
    return _assemble(level, vocabulary, decks, kanji, grammar);
  }

  LevelContent _assemble(
    JlptLevel level,
    Map<String, VocabularyCard> vocabulary,
    List<StudyDeck> decks,
    List<KanjiContent> kanji,
    List<GrammarContent> grammar,
  ) {
    final categories = <DeckCategory, List<VocabularyChapter>>{};
    for (final deck in decks) {
      final category =
          DeckCategory.tryParse(deck.category) ??
          (deck.category == 'vocabulary' ? DeckCategory.other : null);
      if (category == null) continue;
      (categories[category] ??= []).add(
        VocabularyChapter(
          id: deck.id,
          name: deck.title,
          cards: deck.contentIds
              .where(vocabulary.containsKey)
              .map((id) => vocabulary[id]!)
              .toList(),
        ),
      );
    }
    return LevelContent(
      level: level,
      categories: categories,
      vocabulary: vocabulary,
      decks: decks,
      kanji: kanji,
      grammar: grammar,
    );
  }
}
