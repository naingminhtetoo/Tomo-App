import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/storage/content_cache.dart';
import 'package:tomo/core/storage/file_content_cache.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/vocabulary/data/models/content_manifest.dart';
import 'package:tomo/features/vocabulary/data/models/legacy_vocabulary_mapper.dart';
import 'package:tomo/features/vocabulary/domain/entities/deck_category.dart';

void main() {
  const mapper = LegacyVocabularyMapper();
  Map<String, dynamic> word(String meaning) => {
    'word': '把握',
    'reading': 'はあく',
    'meaning': meaning,
  };
  String legacy(List<Map<String, dynamic>> words) => jsonEncode({
    'level': 'N2',
    'other': {
      'chapters': [
        {'name': 'chapter', 'words': words},
      ],
    },
  });
  test(
    'meaning edits, insertions, order and source membership do not change IDs',
    () {
      final first = mapper
          .decode(legacy([word('grasp')]), expectedLevel: JlptLevel.n2)
          .vocabulary
          .values
          .single;
      final changed = mapper.decode(
        legacy([
          {'word': '猫', 'reading': 'ねこ', 'meaning': 'cat'},
          word('understanding'),
        ]),
        expectedLevel: JlptLevel.n2,
      );
      expect(changed.vocabulary.values.last.id, first.id);
      final moved = mapper.decode(
        jsonEncode({
          'level': 'N2',
          'adverbs': {
            'chapters': [
              {
                'name': 'new name',
                'words': [word('grasp')],
              },
            ],
          },
        }),
        expectedLevel: JlptLevel.n2,
      );
      expect(moved.vocabulary.values.single.id, first.id);
    },
  );
  test('duplicate words use one master and retain both deck memberships', () {
    final content = mapper.decode(
      jsonEncode({
        'level': 'N2',
        'kanji': {
          'chapters': [
            {
              'name': 'A',
              'words': [word('grasp')],
            },
          ],
        },
        'other': {
          'chapters': [
            {
              'name': 'B',
              'words': [word('understanding')],
            },
          ],
        },
      }),
      expectedLevel: JlptLevel.n2,
    );
    expect(content.vocabulary.length, 1);
    expect(content.vocabulary.values.single.meanings, [
      'grasp',
      'understanding',
    ]);
    expect(content.decks.map((d) => d.contentIds.single).toSet().length, 1);
    expect(
      identical(
        content.cards(DeckCategory.kanji).single,
        content.cards(DeckCategory.other).single,
      ),
      isTrue,
    );
    expect(
      () => content.decks.first.contentIds.clear(),
      throwsUnsupportedError,
    );
  });
  test('canonical roundtrip supports richer fields and local search', () {
    final id = LegacyVocabularyMapper.legacyId(JlptLevel.n2, '把握', 'はあく');
    final content = mapper.decode(
      jsonEncode({
        'schemaVersion': 1,
        'level': 'N2',
        'vocabulary': [
          {
            'id': id,
            'word': '把握',
            'reading': 'はあく',
            'romaji': 'haaku',
            'meanings': ['grasp', 'understanding'],
            'partOfSpeech': ['noun'],
            'kanjiIds': ['kanji_握'],
            'examples': [
              {'sentence': '把握する。'},
            ],
            'collocations': ['状況を把握する'],
          },
        ],
        'decks': [
          {
            'id': 'deck',
            'title': 'Chapter',
            'level': 'N2',
            'category': 'vocabulary',
            'contentIds': [id],
          },
        ],
        'kanji': [
          {
            'id': 'kanji_握',
            'character': '握',
            'level': 'N2',
            'strokes': 12,
            'meanings': ['grip'],
            'onyomi': ['アク'],
            'kunyomi': ['にぎる'],
          },
        ],
        'grammar': [
          {
            'id': 'n2_grammar_1',
            'pattern': '〜ものの',
            'level': 'N2',
            'meanings': ['although'],
            'formation': ['plain form'],
          },
        ],
      }),
      expectedLevel: JlptLevel.n2,
    );
    for (final query in ['把握', 'はあく', 'GRASP', 'understanding', 'haaku']) {
      expect(content.search(query).single.id, id);
    }
    expect(content.search('absent'), isEmpty);
    final roundtrip = mapper.decode(
      jsonEncode(content.toJson()),
      expectedLevel: JlptLevel.n2,
    );
    expect(roundtrip.grammar.single.pattern, '〜ものの');
    expect(roundtrip.kanji.single.strokes, 12);
    expect(roundtrip.vocabulary[id]!.partOfSpeech, ['noun']);
    expect(roundtrip.vocabulary[id]!.examples.single.translation, isNull);
  });
  test(
    'canonical JSON rejects dangling deck references and unsupported schemas',
    () {
      for (final json in [
        {'schemaVersion': 2, 'level': 'N2', 'vocabulary': [], 'decks': []},
        {
          'schemaVersion': 1,
          'level': 'N2',
          'vocabulary': [],
          'decks': [
            {
              'id': 'x',
              'title': '',
              'level': 'N2',
              'category': 'vocabulary',
              'contentIds': ['missing'],
            },
          ],
        },
      ]) {
        expect(
          () => mapper.decode(jsonEncode(json), expectedLevel: JlptLevel.n2),
          throwsException,
        );
      }
    },
  );
  test(
    'manifest parses independent file versions and rejects unsafe paths',
    () {
      final manifest = ContentManifest.decode(
        jsonEncode({
          'schemaVersion': 1,
          'levels': {
            'N2': {
              'version': 8,
              'files': {
                'vocabulary': {
                  'version': 8,
                  'path': 'n2/vocabulary/words.json',
                },
                'decks': {'version': 3, 'path': 'n2/decks.json'},
              },
            },
          },
        }),
      );
      expect(manifest.files[JlptLevel.n2]!['decks']!.version, 3);
      for (final path in [
        '../secret',
        'https://other.example/data.json',
        '/data.json',
        'n2/%2E%2E/data',
      ]) {
        expect(
          () => ContentFile.fromJson({'version': 1, 'path': path}),
          throwsException,
        );
      }
      expect(
        () => ContentManifest.decode('{"schemaVersion":2,"levels":{}}'),
        throwsException,
      );
    },
  );
  test(
    'file cache survives reopen with versions and leaves no temporary files',
    () async {
      final directory = await Directory.systemTemp.createTemp('tomo-content-');
      addTearDown(() => directory.delete(recursive: true));
      final cache = FileContentCache(directory: () async => directory);
      await cache.write(
        'n2',
        const CachedContent(
          version: 8,
          json: '{"level":"N2"}',
          fileVersions: {'vocabulary': 8, 'decks': 3},
        ),
      );
      final reopened = FileContentCache(directory: () async => directory);
      expect((await reopened.read('n2'))!.fileVersions, {
        'vocabulary': 8,
        'decks': 3,
      });
      expect(
        (await Directory(
          '${directory.path}/tomo_content',
        ).list().toList()).length,
        1,
      );
      await expectLater(
        cache.write('../escape', const CachedContent(version: 1, json: '{}')),
        throwsArgumentError,
      );
    },
  );
}
