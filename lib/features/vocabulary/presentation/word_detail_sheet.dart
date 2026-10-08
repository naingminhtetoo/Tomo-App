import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/ui_action.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../progress/presentation/progress_providers.dart';
import '../../progress/presentation/learning_state_controller.dart';
import '../../progress/domain/progress_repository.dart';
import '../domain/entities/level_content.dart';
import '../domain/entities/vocabulary_card.dart';
import 'vocabulary_controller.dart';

final wordProgressProvider = FutureProvider.autoDispose
    .family<StudyProgress?, String>((ref, id) {
      ref.watch(progressChangesProvider);
      return ref.watch(progressRepositoryProvider).findByCardId(id);
    });

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({super.key, required this.level, required this.id});
  final JlptLevel level;
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'Word Detail',
    showNavigation: false,
    child: ref
        .watch(levelContentProvider(level))
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => const Text('Word content could not be loaded.'),
          data: (snapshot) {
            final card = snapshot.content.vocabulary[id];
            return card == null
                ? const SurfacePanel(child: Text('This word is not installed.'))
                : WordDetailSheet(card: card, content: snapshot.content);
          },
        ),
  );
}

/// Reuses the existing detail component in both routed and sheet contexts.
class WordDetailSheet extends ConsumerWidget {
  const WordDetailSheet({super.key, required this.card, required this.content});
  final VocabularyCard card;
  final LevelContent content;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context), scheme = Theme.of(context).colorScheme;
    final progress = ref.watch(wordProgressProvider(card.id));
    final mutation = ref.read(learningStateControllerProvider.notifier);
    final busy = ref.watch(learningStateControllerProvider);
    final kanji = content.kanji
        .where((k) => card.kanjiIds.contains(k.id))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            const TomoBadge('VOCABULARY'),
            TomoBadge('JLPT ${card.level.label}', accent: false),
          ],
        ),
        const SizedBox(height: 22),
        SurfacePanel(
          accent: true,
          child: Column(
            children: [
              Text(
                card.reading,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    card.word,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 74,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (card.romaji != null) ...[
                const SizedBox(height: 12),
                Text(card.romaji!),
              ],
              if (card.partOfSpeech.isNotEmpty || card.tags.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...card.partOfSpeech.map(
                      (p) => TomoBadge(p, accent: false),
                    ),
                    ...card.tags.map((t) => TomoBadge(t, accent: false)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              ...card.meanings.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(e.value, style: theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        progress.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Learning state could not be loaded.'),
          data: (state) => SurfacePanel(
            padding: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state?.firstLearnedAt == null
                      ? 'Not studied yet'
                      : 'Reviewed ${(state?.correctCount ?? 0) + (state?.incorrectCount ?? 0)} times',
                  style: theme.textTheme.titleMedium,
                ),
                if (state?.nextReviewAt != null)
                  Text(
                    'Next review: ${state!.nextReviewAt!.toLocal().toString().split(' ').first}',
                  ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Favorite'),
                      selected: state?.favorite ?? false,
                      onSelected: busy
                          ? null
                          : (_) => runUiAction(
                              context,
                              () => mutation.toggleFavorite(card.id),
                            ),
                    ),
                    FilterChip(
                      label: const Text('Difficult'),
                      selected: state?.difficult ?? false,
                      onSelected: busy
                          ? null
                          : (_) => runUiAction(
                              context,
                              () => mutation.toggleDifficult(card.id),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (kanji.isNotEmpty) ...[
          const SizedBox(height: 28),
          const SectionHeading('Kanji Breakdown'),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: kanji
                .map(
                  (k) => SizedBox(
                    width: 160,
                    child: SurfacePanel(
                      padding: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            k.character,
                            style: theme.textTheme.headlineLarge,
                          ),
                          if (k.strokes != null) Text('${k.strokes} strokes'),
                          const SizedBox(height: 12),
                          Text(
                            k.meanings.join(', '),
                            style: TextStyle(color: scheme.primary),
                          ),
                          if (k.onyomi.isNotEmpty)
                            Text('On: ${k.onyomi.join(' · ')}'),
                          if (k.kunyomi.isNotEmpty)
                            Text('Kun: ${k.kunyomi.join(' · ')}'),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (card.examples.isNotEmpty || card.exampleSentence != null) ...[
          const SizedBox(height: 28),
          const SectionHeading('Example Sentences'),
          ...card.examples.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SurfacePanel(
                padding: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.sentence, style: theme.textTheme.titleMedium),
                    if (e.translation != null) ...[
                      const SizedBox(height: 12),
                      Text(e.translation!),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (card.exampleSentence != null)
            SurfacePanel(
              padding: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.exampleSentence!),
                  if (card.exampleTranslation != null) ...[
                    const SizedBox(height: 12),
                    Text(card.exampleTranslation!),
                  ],
                ],
              ),
            ),
        ],
        if (card.collocations.isNotEmpty) ...[
          const SizedBox(height: 28),
          const SectionHeading('Collocations & Compounds'),
          ...card.collocations.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfacePanel(padding: 18, child: Text(c)),
            ),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => context.pushNamed(
            AppRoutes.practiceWord,
            pathParameters: {'level': card.level.name, 'id': card.id},
          ),
          icon: const Icon(Icons.school_outlined),
          label: const Text('Practice Word'),
        ),
      ],
    );
  }
}
