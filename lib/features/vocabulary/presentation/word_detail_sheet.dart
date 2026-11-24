import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../app/theme/tomo_theme.dart';
import '../../../core/localization/content_language.dart';
import '../../../core/widgets/learning_detail_components.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/ui_action.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../progress/presentation/progress_providers.dart';
import '../../progress/presentation/learning_state_controller.dart';
import '../../progress/domain/progress_repository.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../domain/entities/content_example.dart';
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
    final selectedLanguage =
        ref.watch(preferencesControllerProvider).value?.explanationLanguage ??
        ContentLanguage.english;
    final progress = ref.watch(wordProgressProvider(card.id));
    final mutation = ref.read(learningStateControllerProvider.notifier);
    final busy = ref.watch(learningStateControllerProvider);
    final kanji = content.kanji
        .where((k) => card.kanjiIds.contains(k.id))
        .toList();
    final authoredExamples = <ContentExample>[
      ...card.examples,
      if (card.exampleSentence?.trim().isNotEmpty == true)
        ContentExample(
          sentence: card.exampleSentence!,
          translation: card.exampleTranslation,
        ),
    ];
    final examples = authoredExamples.map((example) {
      final translation = example.translationFor(selectedLanguage);
      return LearningExampleData(
        sentence: example.sentence,
        translation: translation?.text,
        translationLanguage: translation?.language,
      );
    }).toList();
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
        if (card.explanation.isNotEmpty) ...[
          const SizedBox(height: TomoSpacing.lg),
          LearningExplanationSection(
            explanation: card.explanation,
            selectedLanguage: selectedLanguage,
          ),
        ],
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
        if (examples.isNotEmpty) ...[
          const SizedBox(height: TomoSpacing.lg),
          LearningExampleSection(examples: examples),
        ],
        if (card.collocations.isNotEmpty) ...[
          const SizedBox(height: TomoSpacing.lg),
          LearningDetailSection(
            title: 'Collocations & Compounds',
            icon: Icons.hub_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: card.collocations
                  .map(
                    (collocation) => Padding(
                      padding: const EdgeInsets.only(bottom: TomoSpacing.sm),
                      child: Text('•  $collocation'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}
