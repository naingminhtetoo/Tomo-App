import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/tomo_theme.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_components.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../../core/widgets/ui_action.dart';
import '../../grammar/domain/grammar_content.dart';
import '../../kanji/domain/kanji_content.dart';
import '../../level_selection/data/app_preferences.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../progress/presentation/learning_state_controller.dart';
import '../../progress/presentation/progress_providers.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../../vocabulary/domain/entities/deck_category.dart';
import '../../vocabulary/domain/entities/study_deck.dart';
import '../../vocabulary/domain/entities/vocabulary_card.dart';
import '../domain/study_catalog.dart';
import 'catalog_provider.dart';

class LearningListScreen extends ConsumerStatefulWidget {
  const LearningListScreen({
    super.key,
    required this.level,
    required this.category,
    required this.source,
    required this.deckId,
  });

  final JlptLevel level;
  final StudyCategory category;
  final String source;
  final String deckId;

  @override
  ConsumerState<LearningListScreen> createState() => _LearningListScreenState();
}

class _LearningListScreenState extends ConsumerState<LearningListScreen> {
  String _query = '';
  bool _remembered = false;

  @override
  Widget build(BuildContext context) => TomoScaffold(
    title: 'Learning List',
    showNavigation: false,
    levelLabel: widget.level.label,
    maxContentWidth: 720,
    child: ref
        .watch(studyCatalogProvider(widget.level))
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => ErrorStatus(
            message: 'This learning list could not be loaded.',
            onRetry: () => ref.invalidate(studyCatalogProvider(widget.level)),
          ),
          data: _content,
        ),
  );

  Widget _content(StudyCatalog catalog) {
    final source = catalog
        .sources(widget.category)
        .where((item) => item.id == widget.source)
        .firstOrNull;
    final decks = widget.deckId.startsWith('all:')
        ? source?.decks ?? const <StudyDeck>[]
        : catalog.content.decks
              .where((deck) => deck.id == widget.deckId)
              .toList();
    if (decks.isEmpty) {
      return const TomoEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Learning content unavailable',
        message: 'This chapter is not installed on this device.',
      );
    }
    _remember();
    final ids = decks.expand((deck) => deck.contentIds).toSet();
    final words = ids
        .map((id) => catalog.content.vocabulary[id])
        .whereType<VocabularyCard>()
        .where(_matchesWord)
        .toList();
    final kanji = catalog.content.kanji
        .where((item) => ids.contains(item.id) && _matchesKanji(item))
        .toList();
    final grammar = catalog.content.grammar
        .where((item) => ids.contains(item.id) && _matchesGrammar(item))
        .toList();
    final title = decks.length == 1
        ? StudyCatalog.deckTitle(decks.single)
        : source?.title ?? 'All chapters';
    final total = ids.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TomoSectionLabel('Learn mode'),
        const SizedBox(height: TomoSpacing.sm),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TomoSpacing.xs),
        Text(
          'JLPT ${widget.level.label} · ${widget.category.label} · ${source?.title ?? StudyCatalog.sourceTitle(widget.source)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TomoSpacing.md),
        if (widget.category == StudyCategory.kanji && kanji.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: TomoSpacing.md),
            child: SurfacePanel(
              padding: TomoSpacing.md,
              child: Text(
                'This installed Kanji source contains related vocabulary. Standalone character readings and examples are not included in the current N2 data.',
              ),
            ),
          ),
        Wrap(
          spacing: TomoSpacing.sm,
          runSpacing: TomoSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TomoBadge('$total ${total == 1 ? 'item' : 'items'}', accent: false),
            if (words.isNotEmpty)
              FilledButton.icon(
                key: const Key('practice-flashcards'),
                onPressed: () => _practice(decks.first),
                icon: const Icon(Icons.style_outlined),
                label: const Text('Practice Flashcards'),
              ),
          ],
        ),
        const SizedBox(height: TomoSpacing.md),
        TextField(
          key: const Key('chapter-search'),
          decoration: InputDecoration(
            labelText: 'Search this chapter',
            hintText: 'Japanese, reading, or meaning',
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: TomoSpacing.lg),
        if (words.isNotEmpty)
          _VocabularyList(level: widget.level, words: words),
        if (kanji.isNotEmpty)
          _KanjiList(
            items: kanji,
            words: catalog.content.vocabulary.values.toList(),
          ),
        if (grammar.isNotEmpty) _GrammarList(items: grammar),
        if (words.isEmpty && kanji.isEmpty && grammar.isEmpty)
          TomoEmptyState(
            icon: _query.trim().isEmpty
                ? Icons.inventory_2_outlined
                : Icons.search_off,
            title: _query.trim().isEmpty
                ? 'No supported lessons installed'
                : 'No matching lessons',
            message: _query.trim().isEmpty
                ? 'This chapter has no content that Tomo can display yet.'
                : 'Try another Japanese word, reading, or meaning.',
          ),
      ],
    );
  }

  void _remember() {
    if (_remembered) return;
    _remembered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(preferencesControllerProvider.future);
      if (!mounted) return;
      await ref
          .read(preferencesControllerProvider.notifier)
          .rememberLearning(
            LastLearningActivity(
              level: widget.level,
              category: widget.category.name,
              source: widget.source,
              deckId: widget.deckId,
            ),
          );
    });
  }

  bool _matches(Iterable<String?> values) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        values.any((value) => value?.toLowerCase().contains(query) == true);
  }

  bool _matchesWord(VocabularyCard card) =>
      _matches([card.word, card.reading, card.romaji, ...card.meanings]);

  bool _matchesKanji(KanjiContent item) => _matches([
    item.character,
    ...item.meanings,
    ...item.onyomi,
    ...item.kunyomi,
  ]);

  bool _matchesGrammar(GrammarContent item) => _matches([
    item.pattern,
    item.reading,
    item.explanation,
    ...item.meanings,
    ...item.formation,
  ]);

  void _practice(StudyDeck deck) => context.pushNamed(
    AppRoutes.deck,
    pathParameters: {
      'level': widget.level.name,
      'category': (DeckCategory.tryParse(deck.category) ?? DeckCategory.other)
          .contentKey,
    },
    queryParameters: {
      'deck': widget.deckId,
      'source': widget.source,
      'start': '1',
    },
  );
}

class _VocabularyList extends ConsumerWidget {
  const _VocabularyList({required this.level, required this.words});

  final JlptLevel level;
  final List<VocabularyCard> words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteVocabularyIdsProvider(level));
    final busy = ref.watch(learningStateControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Words', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: TomoSpacing.sm),
        ...words.map(
          (card) => Padding(
            padding: const EdgeInsets.only(bottom: TomoSpacing.sm),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                title: Text(
                  card.word,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${card.reading}\n${card.meanings.join(' · ')}'),
                ),
                isThreeLine: true,
                trailing: IconButton(
                  key: Key('favorite-${card.id}'),
                  tooltip: favorites.value?.contains(card.id) == true
                      ? 'Remove favorite'
                      : 'Add favorite',
                  onPressed: busy
                      ? null
                      : () => runUiAction(
                          context,
                          () => ref
                              .read(learningStateControllerProvider.notifier)
                              .toggleFavorite(card.id),
                        ),
                  icon: Icon(
                    favorites.value?.contains(card.id) == true
                        ? Icons.star
                        : Icons.star_outline,
                    color: favorites.value?.contains(card.id) == true
                        ? Theme.of(context).colorScheme.secondary
                        : null,
                  ),
                ),
                onTap: () => context.pushNamed(
                  AppRoutes.word,
                  pathParameters: {'level': level.name, 'id': card.id},
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KanjiList extends StatelessWidget {
  const _KanjiList({required this.items, required this.words});

  final List<KanjiContent> items;
  final List<VocabularyCard> words;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Kanji', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: TomoSpacing.sm),
      ...items.map((item) => _kanjiCard(context, item)),
    ],
  );

  Widget _kanjiCard(BuildContext context, KanjiContent item) {
    final related = words
        .where((word) => word.kanjiIds.contains(item.id))
        .take(4)
        .toList();
    final examples = related
        .expand(
          (word) => [
            ...word.examples.map((example) => example.sentence),
            if (word.exampleSentence != null) word.exampleSentence!,
          ],
        )
        .take(2)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: TomoSpacing.sm),
      child: SurfacePanel(
        padding: TomoSpacing.md,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.character,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(width: TomoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.meanings.join(' · ')),
                  if (item.onyomi.isNotEmpty)
                    Text('On: ${item.onyomi.join(' · ')}'),
                  if (item.kunyomi.isNotEmpty)
                    Text('Kun: ${item.kunyomi.join(' · ')}'),
                  if (item.strokes != null) Text('${item.strokes} strokes'),
                  if (related.isNotEmpty) ...[
                    const SizedBox(height: TomoSpacing.sm),
                    Text(
                      'Related vocabulary',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    ...related.map(
                      (word) => Text(
                        '${word.word} ${word.reading} · ${word.meanings.join(' · ')}',
                      ),
                    ),
                  ],
                  if (examples.isNotEmpty) ...[
                    const SizedBox(height: TomoSpacing.sm),
                    Text(
                      'Examples',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    ...examples.map(Text.new),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarList extends StatelessWidget {
  const _GrammarList({required this.items});

  final List<GrammarContent> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Grammar', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: TomoSpacing.sm),
      ...items.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: TomoSpacing.sm),
          child: SurfacePanel(
            padding: TomoSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.pattern,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (item.reading != null) Text(item.reading!),
                if (item.meanings.isNotEmpty) ...[
                  const SizedBox(height: TomoSpacing.sm),
                  Text(item.meanings.join(' · ')),
                ],
                if (item.explanation != null) ...[
                  const SizedBox(height: TomoSpacing.sm),
                  Text(item.explanation!),
                ],
                if (item.formation.isNotEmpty) ...[
                  const SizedBox(height: TomoSpacing.sm),
                  Text('Usage: ${item.formation.join(' · ')}'),
                ],
                if (item.examples.isNotEmpty) ...[
                  const SizedBox(height: TomoSpacing.sm),
                  ...item.examples.map(
                    (example) => Text(
                      example.translation == null
                          ? example.sentence
                          : '${example.sentence}\n${example.translation}',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
