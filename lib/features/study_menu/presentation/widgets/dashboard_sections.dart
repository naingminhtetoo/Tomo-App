import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/tomo_theme.dart';
import '../../../../core/widgets/tomo_scaffold.dart';
import '../../../../core/widgets/ui_action.dart';
import '../../../level_selection/domain/jlpt_level.dart';
import '../../../level_selection/data/app_preferences.dart';
import '../../../progress/presentation/progress_providers.dart';
import '../../../progress/presentation/learning_state_controller.dart';
import '../../domain/study_catalog.dart';
import '../catalog_provider.dart';

IconData categoryIcon(StudyCategory c) => switch (c) {
  StudyCategory.vocabulary => Icons.translate,
  StudyCategory.kanji => Icons.edit_note,
  StudyCategory.grammar => Icons.psychology_outlined,
  StudyCategory.adverbs => Icons.chat_bubble_outline,
};

class ContinueStudyCard extends ConsumerWidget {
  const ContinueStudyCard({
    super.key,
    required this.level,
    required this.lastLearning,
  });
  final JlptLevel level;
  final LastLearningActivity? lastLearning;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context), scheme = Theme.of(context).colorScheme;
    final active = ref.watch(activeSessionProvider);
    final session = active.value;
    final catalog = ref.watch(studyCatalogProvider(level)).value;
    final deck = catalog?.content.decks
        .where((d) => d.id == session?.deckId)
        .firstOrNull;
    final browse = lastLearning?.level == level ? lastLearning : null;
    final browseCategory = StudyCategory.tryParse(browse?.category);
    final browseSource = catalog == null || browseCategory == null
        ? null
        : catalog
              .sources(browseCategory)
              .where((source) => source.id == browse?.source)
              .firstOrNull;
    final browseDeck = catalog?.content.decks
        .where((candidate) => candidate.id == browse?.deckId)
        .firstOrNull;
    final canContinueLearning =
        browse != null &&
        browseCategory != null &&
        browseSource != null &&
        (browse.deckId.startsWith('all:') || browseDeck != null);
    final browseTitle = browseDeck == null
        ? browseSource?.title
        : StudyCatalog.deckTitle(browseDeck);
    return SurfacePanel(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TomoBadge(
                    canContinueLearning
                        ? 'CONTINUE LEARNING'
                        : session == null
                        ? 'READY TO LEARN'
                        : 'FLASHCARDS IN PROGRESS',
                  ),
                ),
              ),
              if (session != null)
                IconButton(
                  tooltip: 'End saved session',
                  onPressed: () async {
                    if (await confirmAction(
                          context,
                          title: 'End saved session?',
                          message: 'Your recorded reviews will stay saved.',
                          confirm: 'End session',
                        ) &&
                        context.mounted) {
                      await runUiAction(
                        context,
                        ref
                            .read(learningStateControllerProvider.notifier)
                            .endActiveSession,
                      );
                    }
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            canContinueLearning
                ? browseTitle ?? 'Continue your learning list'
                : session == null
                ? 'Your next chapter\nstarts here'
                : deck == null
                ? 'Continue your study session'
                : StudyCatalog.deckTitle(deck),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (canContinueLearning) ...[
            Text(
              'JLPT ${level.label} · ${browseCategory.label} · ${browseSource.title}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (session != null) ...[
              const SizedBox(height: 10),
              Text(
                'An unfinished flashcard session is also ready to resume.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ] else if (active.hasError)
            const Text('Your saved session could not be loaded.')
          else if (session != null) ...[
            Text(
              'Card ${session.currentIndex + 1} of ${session.contentIds.length} · JLPT ${session.level.toUpperCase()}',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (session.currentIndex + 1) / session.contentIds.length,
            ),
          ] else
            Text(
              'Choose a local ${level.label} collection and browse every word before practicing.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 26),
          if (canContinueLearning)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('home-study-button'),
                onPressed: () => context.pushNamed(
                  AppRoutes.learningList,
                  pathParameters: {
                    'level': browse.level.name,
                    'kind': browse.category,
                  },
                  queryParameters: {
                    'source': browse.source,
                    'deck': browse.deckId,
                  },
                ),
                icon: const Icon(Icons.view_list_outlined),
                iconAlignment: IconAlignment.end,
                label: const Text('Continue Learning'),
              ),
            )
          else if (session == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('home-study-button'),
                onPressed: active.isLoading
                    ? null
                    : () => context.pushNamed(
                        AppRoutes.study,
                        pathParameters: {'level': level.name},
                      ),
                icon: const Icon(Icons.arrow_forward),
                iconAlignment: IconAlignment.end,
                label: const Text('Start Learning'),
              ),
            ),
          if (session != null) ...[
            if (canContinueLearning) const SizedBox(height: TomoSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.pushNamed(
                  AppRoutes.session,
                  pathParameters: {'level': session.level},
                ),
                icon: const Icon(Icons.style_outlined),
                label: const Text('Resume Flashcards'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProgressSummary extends ConsumerWidget {
  const ProgressSummary({super.key, required this.level});
  final JlptLevel level;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(progressSummaryProvider(level))
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Progress could not be loaded.'),
        data: (summary) => SurfacePanel(
          padding: 16,
          child: Row(
            children: [
              Expanded(
                child: _Stat('${summary.reviewedToday}', 'Reviewed today'),
              ),
              Expanded(
                child: _Stat('${summary.learnedToday}', 'Learned today'),
              ),
              Expanded(
                child: _Stat(
                  summary.totalReviews == 0
                      ? '—'
                      : '${(summary.accuracy * 100).round()}%',
                  'Accuracy',
                  accent: true,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, {this.accent = false});
  final String value, label;
  final bool accent;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 3),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class DailyReviewCard extends ConsumerWidget {
  const DailyReviewCard({super.key, required this.level});
  final JlptLevel level;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(progressSummaryProvider(level))
      .when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const Text('Review data could not be loaded.'),
        data: (summary) => SurfacePanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Review Queue',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TomoBadge('${summary.dueCount} due'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.dueCount == 0
                    ? 'No reviews are due. Keep studying to build your learning history.'
                    : 'Review words that are due from your saved learning state.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.go('/review'),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Open Daily Review'),
                ),
              ),
            ],
          ),
        ),
      );
}

class StudyGrid extends ConsumerWidget {
  const StudyGrid({super.key, required this.level});
  final JlptLevel level;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(studyCatalogProvider(level))
      .when(
        loading: () => const LinearProgressIndicator(),
        error: (_, _) => const Text('Local collections could not be loaded.'),
        data: (catalog) => LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 16) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: StudyCategory.values.map((category) {
                final progress = catalog.categoryProgress[category]!;
                return SizedBox(
                  width: width,
                  child: Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TomoRadii.card),
                      onTap: () => context.pushNamed(
                        AppRoutes.category,
                        pathParameters: {
                          'level': level.name,
                          'kind': category.name,
                        },
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  categoryIcon(category),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const Spacer(),
                                Text(
                                  '${(progress.fraction * 100).round()}%',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              category.label,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              progress.total == 0
                                  ? 'Not available yet'
                                  : '${progress.learned} / ${progress.total} items',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 18),
                            LinearProgressIndicator(value: progress.fraction),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      );
}
