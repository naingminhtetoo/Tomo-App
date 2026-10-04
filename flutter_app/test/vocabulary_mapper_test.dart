import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/errors/content_exception.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/vocabulary/data/models/content_manifest.dart';
import 'package:tomo/features/vocabulary/data/models/legacy_vocabulary_mapper.dart';
import 'package:tomo/features/vocabulary/domain/entities/deck_category.dart';

void main() {
  const mapper = LegacyVocabularyMapper();
  final source = File('assets/data/n2.json').readAsStringSync();
  test(
    'adapts every bundled N2 card, preserves Unicode and empty categories',
    () {
      final content = mapper.decode(source, expectedLevel: JlptLevel.n2);
      expect(content.cards(DeckCategory.kanji).length, 1591);
      expect(content.cards(DeckCategory.kanjiMaster).length, 134);
      expect(content.cards(DeckCategory.adverb).length, 87);
      expect(content.cards(DeckCategory.vocabularyShinkanzen), isEmpty);
      expect(content.cards(DeckCategory.vocabularySoumatome), isEmpty);
      expect(content.cards(DeckCategory.other), isEmpty);
      final first = content.cards(DeckCategory.kanji).first;
      expect(first.word, '禁止');
      expect(first.reading, 'きんし');
      expect(first.meanings, ['prohibition']);
      expect(content.chapters(DeckCategory.adverb).single.name, '');
      final cards = DeckCategory.values.expand(content.cards).toList();
      expect(cards.map((card) => card.id).toSet().length, 1812);
      expect(
        mapper
            .decode(source, expectedLevel: JlptLevel.n2)
            .cards(DeckCategory.kanji)
            .first
            .id,
        first.id,
      );
      expect(() => content.categories.clear(), throwsUnsupportedError);
      expect(() => first.meanings.add('changed'), throwsUnsupportedError);
    },
  );
  test('content copy is byte-for-byte identical to preserved Ionic data', () {
    expect(
      File('assets/data/n2.json').readAsBytesSync(),
      File('../src/assets/datas/n2.json').readAsBytesSync(),
    );
  });
  test('rejects a mismatched level and malformed chapter data', () {
    expect(
      () => mapper.decode(source, expectedLevel: JlptLevel.n3),
      throwsA(isA<ContentException>()),
    );
    expect(
      () => mapper.decode(
        '{"level":"N2","kanji":{"chapters":{}}}',
        expectedLevel: JlptLevel.n2,
      ),
      throwsA(isA<ContentException>()),
    );
  });
  test(
    'supports explicit IDs, multiple meanings and future optional metadata',
    () {
      final content = mapper.decode(
        jsonEncode({
          'level': 'N2',
          'other': {
            'chapters': [
              {
                'name': '',
                'words': [
                  {
                    'id': 'published-id',
                    'word': '猫',
                    'reading': 'ねこ',
                    'meanings': ['cat', 'feline'],
                    'tags': ['animal'],
                    'difficulty': 2,
                    'exampleSentence': '猫がいる。',
                    'exampleTranslation': 'There is a cat.',
                  },
                ],
              },
            ],
          },
        }),
        expectedLevel: JlptLevel.n2,
      );
      final card = content.cards(DeckCategory.other).single;
      expect(card.id, 'published-id');
      expect(card.meanings, ['cat', 'feline']);
      expect(card.tags, ['animal']);
      expect(card.difficulty, 2);
      expect(card.exampleSentence, '猫がいる。');
    },
  );
  test('rejects duplicate explicit card IDs', () {
    final card = {
      'id': 'duplicate',
      'word': '猫',
      'reading': 'ねこ',
      'meaning': 'cat',
    };
    expect(
      () => mapper.decode(
        jsonEncode({
          'level': 'N2',
          'other': {
            'chapters': [
              {
                'name': '',
                'words': [card, card],
              },
            ],
          },
        }),
        expectedLevel: JlptLevel.n2,
      ),
      throwsA(isA<ContentException>()),
    );
  });
  test(
    'manifest represents only published bundled levels and validates versions',
    () {
      expect(
        ContentManifest.decode(
          File('assets/data/content-manifest.json').readAsStringSync(),
        ).versions,
        {JlptLevel.n2: 1},
      );
      expect(
        () => ContentManifest.decode('{"n2":{"version":0}}'),
        throwsA(isA<ContentException>()),
      );
    },
  );
}
