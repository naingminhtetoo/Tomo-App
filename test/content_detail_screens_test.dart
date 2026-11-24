import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tomo/app/app.dart';
import 'package:tomo/app/providers.dart';
import 'package:tomo/app/router/app_router.dart';
import 'package:tomo/core/database/app_database.dart';
import 'package:tomo/core/localization/content_language.dart';
import 'package:tomo/features/grammar/domain/grammar_content.dart';
import 'package:tomo/features/kanji/domain/kanji_content.dart';
import 'package:tomo/features/level_selection/data/app_preferences.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/vocabulary/domain/entities/content_example.dart';
import 'package:tomo/features/vocabulary/domain/entities/deck_category.dart';
import 'package:tomo/features/vocabulary/domain/entities/level_content.dart';
import 'package:tomo/features/vocabulary/domain/entities/study_deck.dart';
import 'package:tomo/features/vocabulary/domain/entities/vocabulary_card.dart';
import 'package:tomo/features/vocabulary/domain/repositories/vocabulary_repository.dart';

import 'support/test_repositories.dart';

void main() {
  testWidgets('Word Detail presents authored examples and learning notes', (
    tester,
  ) async {
    final harness = await _pumpFixture(tester);
    harness.router.go('/study/n2/word/word_dream');
    await tester.pumpAndSettle();

    expect(find.text('Word Detail'), findsOneWidget);
    expect(find.text('夢を見る。'), findsOneWidget);
    expect(find.text('私は夢を見ます。'), findsOneWidget);
    expect(find.text('အိပ်မက်မက်သည်။'), findsOneWidget);
    expect(find.text('Japanese explanation'), findsOneWidget);
    expect(find.text('Burmese explanation'), findsOneWidget);
    expect(find.text('Burmese translation'), findsOneWidget);
    expect(find.text('Collocations & Compounds'), findsOneWidget);
    expect(find.text('•  将来の夢'), findsOneWidget);
    expect(find.text('Practice Word'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kanji Learning List item opens readings and linked examples', (
    tester,
  ) async {
    final harness = await _pumpFixture(tester, textScaleFactor: 1.4);
    harness.router.go(
      '/study/n2/learn/kanji?source=kanji_fixture&deck=kanji-detail-deck',
    );
    await tester.pumpAndSettle();

    final item = find.byKey(const Key('kanji-item-kanji_dream'));
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(find.text('Kanji Detail'), findsOneWidget);
    expect(find.text('dream · vision'), findsOneWidget);
    expect(find.text('ON’YOMI 音読み'), findsOneWidget);
    expect(find.text('ム'), findsOneWidget);
    expect(find.text('KUN’YOMI 訓読み'), findsOneWidget);
    expect(find.text('ゆめ'), findsOneWidget);
    expect(find.text('Related Vocabulary'), findsOneWidget);
    expect(find.text('夢に向かって努力する。'), findsOneWidget);
    expect(find.text('အိပ်မက်ဆီသို့ ကြိုးစားသည်။'), findsOneWidget);
    expect(find.text('Japanese explanation'), findsOneWidget);
    expect(find.text('Burmese explanation'), findsOneWidget);
    expect(find.text('Practice Word'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Grammar Learning List item opens explanation and examples', (
    tester,
  ) async {
    final harness = await _pumpFixture(tester);
    harness.router.go(
      '/study/n2/learn/grammar?source=grammar_fixture&deck=grammar-detail-deck',
    );
    await tester.pumpAndSettle();

    final item = find.byKey(const Key('grammar-item-grammar_mono_no'));
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(find.text('Grammar Detail'), findsOneWidget);
    expect(find.text('Explanation'), findsOneWidget);
    expect(
      find.text(
        'မျှော်လင့်ထားသောရလဒ်နှင့် အမှန်တကယ်ရလဒ် ကွာခြားမှုကို ဖော်ပြသည်။',
      ),
      findsOneWidget,
    );
    expect(find.text('Formation & Usage'), findsOneWidget);
    expect(find.text('plain form + ものの'), findsOneWidget);
    expect(find.text('買ったものの、まだ使っていない。'), findsOneWidget);
    expect(find.text('ဝယ်ခဲ့ပေမယ့် မသုံးရသေးပါ။'), findsOneWidget);
    expect(find.text('Practice Word'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _DetailHarness {
  const _DetailHarness(this.router);

  final GoRouter router;
}

Future<_DetailHarness> _pumpFixture(
  WidgetTester tester, {
  double textScaleFactor = 1,
}) async {
  tester.view.physicalSize = const Size(393, 1000);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScaleFactor;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final database = AppDatabase(NativeDatabase.memory());
  final preferences = MemoryPreferences();
  await preferences.write('explanation_language', 'my');
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      vocabularyRepositoryProvider.overrideWithValue(
        _DetailVocabularyRepository(),
      ),
      preferencesRepositoryProvider.overrideWithValue(
        AppPreferencesRepository(preferences),
      ),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await database.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TomoApp()),
  );
  await tester.pumpAndSettle();
  return _DetailHarness(container.read(appRouterProvider));
}

class _DetailVocabularyRepository implements VocabularyRepository {
  final LevelContent _content = LevelContent(
    level: JlptLevel.n2,
    categories: const {},
    vocabulary: {
      'word_dream': VocabularyCard(
        id: 'word_dream',
        word: '夢を見る',
        reading: 'ゆめをみる',
        meanings: const ['to dream', 'to have a vision'],
        level: JlptLevel.n2,
        category: DeckCategory.other,
        kanjiIds: const ['kanji_dream'],
        partOfSpeech: const ['expression'],
        tags: const ['common'],
        explanation: const LocalizedText(
          japanese: '私は夢を見ます。',
          english: 'An expression about dreaming or having a vision.',
          burmese:
              'အိပ်မက်မက်ခြင်း သို့မဟုတ် ရည်မှန်းချက်ရှိခြင်းကို ဖော်ပြသည်။',
        ),
        examples: const [
          ContentExample(
            sentence: '夢を見る。',
            translations: LocalizedText(
              english: 'I have a dream.',
              burmese: 'အိပ်မက်မက်သည်။',
            ),
          ),
        ],
        collocations: const ['将来の夢'],
      ),
    },
    kanji: [
      KanjiContent(
        id: 'kanji_dream',
        character: '夢',
        level: JlptLevel.n2,
        strokes: 13,
        meanings: const ['dream', 'vision'],
        onyomi: const ['ム'],
        kunyomi: const ['ゆめ'],
        explanation: const LocalizedText(
          japanese: '寝ているときに見るイメージや、将来の希望を表す漢字。',
          english: 'A kanji for dreams and future hopes.',
          burmese: 'အိပ်မက်နှင့် အနာဂတ်မျှော်လင့်ချက်ကို ဖော်ပြသော ခန်းဂျီး။',
        ),
        examples: const [
          ContentExample(
            sentence: '夢に向かって努力する。',
            translations: LocalizedText(
              english: 'Work toward a dream.',
              burmese: 'အိပ်မက်ဆီသို့ ကြိုးစားသည်။',
            ),
          ),
        ],
      ),
    ],
    grammar: [
      GrammarContent(
        id: 'grammar_mono_no',
        pattern: '〜ものの',
        reading: 'ものの',
        level: JlptLevel.n2,
        meanings: const ['although', 'even though'],
        explanation: 'Contrasts an expected result with the actual result.',
        explanations: const LocalizedText(
          japanese: '予想される結果と実際の結果の違いを表す。',
          burmese:
              'မျှော်လင့်ထားသောရလဒ်နှင့် အမှန်တကယ်ရလဒ် ကွာခြားမှုကို ဖော်ပြသည်။',
        ),
        formation: const ['plain form + ものの'],
        tags: const ['contrast'],
        examples: const [
          ContentExample(
            sentence: '買ったものの、まだ使っていない。',
            translations: LocalizedText(
              english: 'Although I bought it, I have not used it yet.',
              burmese: 'ဝယ်ခဲ့ပေမယ့် မသုံးရသေးပါ။',
            ),
          ),
        ],
      ),
    ],
    decks: [
      StudyDeck(
        id: 'kanji-detail-deck',
        title: 'Dream Kanji',
        level: JlptLevel.n2,
        category: 'kanji',
        source: 'kanji_fixture',
        contentIds: const ['word_dream', 'kanji_dream'],
      ),
      StudyDeck(
        id: 'grammar-detail-deck',
        title: 'Contrast Grammar',
        level: JlptLevel.n2,
        category: 'grammar',
        source: 'grammar_fixture',
        contentIds: const ['grammar_mono_no'],
      ),
    ],
  );

  @override
  Future<ContentSnapshot> loadLocal(JlptLevel level) async => ContentSnapshot(
    content: _content,
    version: 1,
    source: ContentSource.bundled,
  );

  @override
  Future<ContentSnapshot?> checkForUpdate(
    JlptLevel level, {
    required int currentVersion,
  }) async => null;
}
