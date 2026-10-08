import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../progress/presentation/progress_providers.dart';
import '../../progress/domain/progress_repository.dart';
import '../domain/entities/level_content.dart';
import '../domain/entities/vocabulary_card.dart';

final wordProgressProvider = FutureProvider.autoDispose
    .family<StudyProgress?, String>((ref, id) {
      ref.watch(progressChangesProvider);
      return ref.watch(progressRepositoryProvider).findByCardId(id);
    });

class WordDetailSheet extends ConsumerWidget {
  const WordDetailSheet({super.key, required this.card, required this.content});
  final VocabularyCard card;
  final LevelContent content;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(wordProgressProvider(card.id));
    final kanji = content.kanji.where((k) => card.kanjiIds.contains(k.id));
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(card.word, style: Theme.of(context).textTheme.headlineLarge),
            Text(card.reading),
            Text('JLPT ${card.level.label}'),
            if (card.romaji != null) Text(card.romaji!),
            const SizedBox(height: 16),
            ...card.meanings.map((m) => Text(m)),
            if (card.partOfSpeech.isNotEmpty)
              Text(card.partOfSpeech.join(', ')),
            if (kanji.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Kanji Breakdown'),
              ...kanji.map(
                (k) => Text('${k.character} · ${k.meanings.join(', ')}'),
              ),
            ],
            if (card.examples.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Examples'),
              ...card.examples.map(
                (e) => Text('${e.sentence}\n${e.translation ?? ''}'),
              ),
            ],
            if (card.exampleSentence != null) Text(card.exampleSentence!),
            if (card.collocations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Collocations'),
              ...card.collocations.map((c) => Text(c)),
            ],
            const SizedBox(height: 16),
            progress.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('Could not load learning state.'),
              data: (state) => Wrap(
                spacing: 12,
                children: [
                  FilterChip(
                    label: const Text('Favorite'),
                    selected: state?.favorite ?? false,
                    onSelected: (_) => ref
                        .read(progressRepositoryProvider)
                        .toggleFavorite(card.id),
                  ),
                  FilterChip(
                    label: const Text('Difficult'),
                    selected: state?.difficult ?? false,
                    onSelected: (_) => ref
                        .read(progressRepositoryProvider)
                        .toggleDifficult(card.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
