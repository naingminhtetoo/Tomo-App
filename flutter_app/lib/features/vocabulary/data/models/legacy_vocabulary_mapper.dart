import 'dart:convert';
import '../../../../core/errors/content_exception.dart';
import '../../../level_selection/domain/jlpt_level.dart';
import '../../domain/entities/deck_category.dart';
import '../../domain/entities/level_content.dart';
import '../../domain/entities/vocabulary_card.dart';

/// Adapts legacy JSON without rewriting it. Explicit future IDs take priority.
class LegacyVocabularyMapper {
  const LegacyVocabularyMapper();

  LevelContent decode(String source, {required JlptLevel expectedLevel}) {
    final root = _object(jsonDecode(source));
    if (JlptLevel.tryParse(root['level'] as String?) != expectedLevel) {
      throw const ContentException('Content level does not match the requested level.');
    }
    final categories = <DeckCategory, List<VocabularyChapter>>{};
    final ids = <String>{};
    for (final category in DeckCategory.values) {
      final section = root[category.contentKey];
      if (section == null) continue;
      final rawChapters = _list(_object(section)['chapters']);
      final chapters = <VocabularyChapter>[];
      for (var ci = 0; ci < rawChapters.length; ci++) {
        final chapter = _object(rawChapters[ci]);
        final name = _string(chapter['name']);
        final chapterId = '${expectedLevel.name}/${category.contentKey}/$ci';
        final cards = <VocabularyCard>[];
        // Ordinal IDs are deterministic for the bundled legacy snapshot.
        // Published stable IDs are required before durable progress ships.
        final words = _list(chapter['words']);
        for (var wi = 0; wi < words.length; wi++) {
          final word = _object(words[wi]);
          final id = word['id'] == null ? '$chapterId/$wi' : _string(word['id']);
          if (id.isEmpty || !ids.add(id)) throw const ContentException('Duplicate or empty card ID.');
          final meanings = word['meanings'] == null
              ? [_string(word['meaning'])]
              : _list(word['meanings']).map(_string).toList();
          if (meanings.isEmpty) throw const ContentException('Card has no meanings.');
          cards.add(VocabularyCard(
            id: id, word: _string(word['word']), reading: _string(word['reading']),
            meanings: meanings, level: expectedLevel, category: category, chapter: name,
            exampleSentence: word['exampleSentence'] == null ? null : _string(word['exampleSentence']),
            exampleTranslation: word['exampleTranslation'] == null ? null : _string(word['exampleTranslation']),
            tags: word['tags'] == null ? const [] : _list(word['tags']).map(_string).toList(),
            difficulty: word['difficulty'] as int?,
          ));
        }
        chapters.add(VocabularyChapter(id: chapterId, name: name, cards: cards));
      }
      categories[category] = chapters;
    }
    return LevelContent(level: expectedLevel, categories: categories);
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) throw const ContentException('Expected a JSON object.');
    return value;
  }
  List<dynamic> _list(Object? value) {
    if (value is! List) throw const ContentException('Expected a JSON array.');
    return value;
  }
  String _string(Object? value) {
    if (value is! String) throw const ContentException('Expected a text field.');
    return value;
  }
}
