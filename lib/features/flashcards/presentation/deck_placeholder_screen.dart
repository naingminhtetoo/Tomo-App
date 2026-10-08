import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../progress/domain/progress_repository.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../../vocabulary/domain/entities/deck_category.dart';
import '../../vocabulary/domain/entities/level_content.dart';
import '../../vocabulary/domain/entities/study_deck.dart';
import '../../vocabulary/domain/entities/vocabulary_card.dart';

/// Evolves the existing deck route into a minimal local study flow.
class DeckPlaceholderScreen extends ConsumerStatefulWidget {
  const DeckPlaceholderScreen({
    super.key,
    required this.level,
    required this.category,
    this.deckId,
  });
  final JlptLevel level;
  final DeckCategory category;
  final String? deckId;
  @override
  ConsumerState<DeckPlaceholderScreen> createState() => _DeckState();
}

class _DeckState extends ConsumerState<DeckPlaceholderScreen> {
  LevelContent? _content;
  List<StudyDeck> _decks = [];
  StudyDeck? _deck;
  ActiveStudySession? _active;
  bool _flipped = false, _busy = false, _shuffle = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await ref
          .read(vocabularyRepositoryProvider)
          .loadLocal(widget.level);
      final preferences = await ref.read(preferencesControllerProvider.future);
      final active = await ref
          .read(progressRepositoryProvider)
          .loadActiveSession();
      final decks = snapshot.content.decks
          .where(
            (d) =>
                (DeckCategory.tryParse(d.category) ?? DeckCategory.other) ==
                    widget.category &&
                d.contentIds.any(snapshot.content.vocabulary.containsKey),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _content = snapshot.content;
        _shuffle = preferences.shuffle;
        _decks = decks;
        final matching = decks.where(
          (d) => d.id == (widget.deckId ?? active?.deckId),
        );
        _deck = matching.isEmpty
            ? (decks.isEmpty ? null : decks.first)
            : matching.first;
        if (active != null &&
            active.deckId == _deck?.id &&
            active.level == widget.level.name) {
          if (active.contentIds.any(
            (id) => !snapshot.content.vocabulary.containsKey(id),
          )) {
            _error =
                'Some saved session content is no longer installed. Clear the session to start again.';
          } else {
            _active = active;
            _shuffle = active.shuffleEnabled;
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load local study data.');
    }
  }

  Future<void> _perform(Future<void> Function() operation) async {
    setState(() => _busy = true);
    try {
      await operation();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Study state could not be saved. $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    final repository = ref.read(progressRepositoryProvider);
    final existing = await repository.loadActiveSession();
    if (existing != null) {
      throw StateError(
        'Resume or clear your unfinished session before starting another.',
      );
    }
    final ids = _deck!.contentIds
        .where(_content!.vocabulary.containsKey)
        .toSet()
        .toList();
    if (_shuffle) ids.shuffle(Random());
    final now = DateTime.now();
    final active = ActiveStudySession(
      sessionId:
          'session_${now.microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
      deckId: _deck!.id,
      level: widget.level.name,
      currentIndex: 0,
      studyMode: 'flashcards',
      shuffleEnabled: _shuffle,
      startedAt: now,
      updatedAt: now,
      contentIds: ids,
    );
    await repository.saveActiveSession(active);
    if (mounted) {
      setState(() {
        _active = active;
        _error = null;
      });
    }
  }

  Future<void> _review(ReviewRating rating) async {
    final active = _active!;
    final repository = ref.read(progressRepositoryProvider);
    await repository.recordReview(
      active.contentIds[active.currentIndex],
      rating,
      sessionId: active.sessionId,
      advanceActiveSession: true,
    );
    final next = await repository.loadActiveSession();
    if (mounted) {
      setState(() {
        _active = next;
        _flipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final VocabularyCard? card = active == null
        ? null
        : _content?.vocabulary[active.contentIds[active.currentIndex]];
    return TomoScaffold(
      title: '${widget.level.label} · ${widget.category.label}',
      child: Column(
        children: [
          if (_error != null) Text(_error!),
          if (_busy) const LinearProgressIndicator(),
          if (_content == null && _error == null)
            const CircularProgressIndicator(),
          if (_content != null && _decks.isEmpty)
            const Text('No vocabulary is installed for this collection.'),
          if (_deck != null && active == null) ...[
            DropdownButton<String>(
              isExpanded: true,
              value: _deck!.id,
              items: _decks
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(d.title.isEmpty ? d.category : d.title),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (id) => setState(
                      () => _deck = _decks.firstWhere((d) => d.id == id),
                    ),
            ),
            SwitchListTile(
              title: const Text('Shuffle'),
              value: _shuffle,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _shuffle = value),
            ),
            FilledButton(
              onPressed: _busy ? null : () => _perform(_start),
              child: const Text('Start studying'),
            ),
          ],
          if (card != null) ...[
            Text('${active!.currentIndex + 1} / ${active.contentIds.length}'),
            const SizedBox(height: 20),
            Card(
              child: InkWell(
                onTap: _busy
                    ? null
                    : () => setState(() => _flipped = !_flipped),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        card.word,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      if (_flipped) ...[
                        const SizedBox(height: 16),
                        Text(card.reading),
                        Text(card.meanings.join('; ')),
                        if (card.examples.isNotEmpty)
                          ...card.examples.map(
                            (e) =>
                                Text('${e.sentence}\n${e.translation ?? ''}'),
                          ),
                        if (card.exampleSentence != null)
                          Text(card.exampleSentence!),
                        if (card.collocations.isNotEmpty)
                          Text(card.collocations.join(' · ')),
                      ] else
                        const Text('Tap to reveal'),
                    ],
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _perform(() async {
                          await ref
                              .read(progressRepositoryProvider)
                              .toggleFavorite(card.id);
                        }),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Toggle favorite'),
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _perform(() async {
                          await ref
                              .read(progressRepositoryProvider)
                              .toggleDifficult(card.id);
                        }),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Toggle difficult'),
                ),
              ],
            ),
            if (_flipped)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReviewRating.values
                    .map(
                      (rating) => FilledButton.tonal(
                        onPressed: _busy
                            ? null
                            : () => _perform(() => _review(rating)),
                        child: Text(rating.name),
                      ),
                    )
                    .toList(),
              ),
          ],
          const SizedBox(height: 20),
          TextButton(
            onPressed: _busy
                ? null
                : () => _perform(() async {
                    await ref
                        .read(progressRepositoryProvider)
                        .clearActiveSession();
                    if (mounted) {
                      setState(() {
                        _active = null;
                        _error = null;
                        _flipped = false;
                      });
                    }
                  }),
            child: const Text('Clear unfinished session'),
          ),
        ],
      ),
    );
  }
}
