import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/localization/content_language.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/vocabulary/data/models/legacy_vocabulary_mapper.dart';

void main() {
  const mapper = LegacyVocabularyMapper();

  test('existing bundled N2 JSON remains backward compatible', () async {
    final source = await File('assets/data/n2.json').readAsString();
    final content = mapper.decode(source, expectedLevel: JlptLevel.n2);
    final originalIds = content.vocabulary.keys.toList();

    expect(content.vocabulary, isNotEmpty);
    expect(content.kanji, isEmpty);
    expect(content.grammar, isEmpty);

    final roundtrip = mapper.decode(
      jsonEncode(content.toJson()),
      expectedLevel: JlptLevel.n2,
    );
    expect(roundtrip.vocabulary.keys, originalIds);
    expect(
      roundtrip.decks.map((deck) => deck.id),
      content.decks.map((d) => d.id),
    );
  });

  test(
    'pilot parses vocabulary, kanji, grammar, and language fallback',
    () async {
      final source = await File(
        'test/fixtures/multilingual_content_pilot.json',
      ).readAsString();
      final content = mapper.decode(source, expectedLevel: JlptLevel.n2);

      expect(content.vocabulary, hasLength(10));
      expect(content.kanji, hasLength(5));
      expect(content.grammar, hasLength(3));

      final improvement = content.vocabulary['pilot_vocab_kaizen']!;
      expect(
        improvement.explanation.resolve(ContentLanguage.burmese)?.language,
        ContentLanguage.burmese,
      );
      expect(
        improvement.examples.first
            .translationFor(ContentLanguage.burmese)
            ?.text,
        contains('လုပ်ငန်းခွင်'),
      );

      final safety = content.vocabulary['pilot_vocab_anzen']!;
      final englishFallback = safety.explanation.resolve(
        ContentLanguage.burmese,
      )!;
      expect(englishFallback.language, ContentLanguage.english);
      expect(englishFallback.text, contains('no danger'));

      final inquiry = content.vocabulary['pilot_vocab_toiawase']!;
      final japaneseFallback = inquiry.explanation.resolve(
        ContentLanguage.burmese,
      )!;
      expect(japaneseFallback.language, ContentLanguage.japanese);
      expect(japaneseFallback.text, startsWith('分からない'));
      expect(
        inquiry.explanation.resolve(ContentLanguage.japanese)?.language,
        ContentLanguage.japanese,
      );

      final legacyExample = content
          .vocabulary['pilot_vocab_keikaku']!
          .examples
          .single
          .translationFor(ContentLanguage.burmese)!;
      expect(legacyExample.language, ContentLanguage.english);
      expect(legacyExample.text, 'Make a travel plan.');

      final kanji = content.kanji.firstWhere(
        (item) => item.id == 'pilot_kanji_kai',
      );
      expect(kanji.explanation.burmese, contains('ပြောင်းလဲခြင်း'));
      expect(kanji.examples.single.sentence, '計画を改める。');

      final multilingualGrammar = content.grammar.first;
      expect(multilingualGrammar.explanations.japanese, isNotEmpty);
      expect(multilingualGrammar.explanations.burmese, isNotEmpty);
      final legacyGrammar = content.grammar.last;
      expect(legacyGrammar.explanation, startsWith('Used when'));
      expect(legacyGrammar.explanations, isEmpty);
    },
  );

  test(
    'schema-v1 serialization preserves multilingual fields and stable IDs',
    () async {
      final source = await File(
        'test/fixtures/multilingual_content_pilot.json',
      ).readAsString();
      final original = mapper.decode(source, expectedLevel: JlptLevel.n2);
      final encoded = jsonEncode(original.toJson());
      final restored = mapper.decode(encoded, expectedLevel: JlptLevel.n2);

      expect(restored.vocabulary.keys, original.vocabulary.keys);
      expect(
        restored.decks.map((deck) => deck.contentIds),
        original.decks.map((d) => d.contentIds),
      );
      expect(restored.vocabulary['pilot_vocab_kaizen']!.explanation.toJson(), {
        'ja': '悪いところや問題点を直し、よりよい状態にすること。',
        'en': 'Correcting problems to make a situation better.',
        'my': 'ပြဿနာရှိသော အခြေအနေကို ပြုပြင်ပြီး ပိုကောင်းအောင်လုပ်ခြင်း။',
      });
      expect(
        restored
            .vocabulary['pilot_vocab_kaizen']!
            .examples
            .first
            .translations
            .burmese,
        contains('လုပ်ငန်းခွင်'),
      );
      expect(restored.kanji.first.explanation.english, contains('changing'));
      expect(
        restored.kanji.first.examples.first.translations.burmese,
        isNotEmpty,
      );
      expect(restored.grammar.first.explanations.burmese, isNotEmpty);
      expect(
        restored.grammar.last.explanation,
        original.grammar.last.explanation,
      );
    },
  );

  test('missing optional multilingual fields are safe', () {
    final content = mapper.decode(
      jsonEncode({
        'schemaVersion': 1,
        'level': 'N2',
        'vocabulary': [
          {
            'id': 'minimal',
            'word': '語',
            'reading': 'ご',
            'meanings': ['word'],
          },
        ],
        'kanji': [],
        'grammar': [],
        'decks': [],
      }),
      expectedLevel: JlptLevel.n2,
    );

    final item = content.vocabulary['minimal']!;
    expect(item.explanation, isA<LocalizedText>());
    expect(item.explanation.isEmpty, isTrue);
    expect(item.examples, isEmpty);
  });
}
