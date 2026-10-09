import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/tomo_theme.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_components.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../progress/domain/progress_repository.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../../study_menu/domain/study_catalog.dart';
import '../../study_menu/presentation/catalog_provider.dart';
import 'progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider);
    return TomoScaffold(
      title: 'Progress',
      brandHeader: true,
      sectionLabel: 'Progress',
      levelLabel: preferences.value?.level.label,
      maxContentWidth: 720,
      child: preferences.when(
        loading: () => const LoadingStatus(),
        error: (_, _) => ErrorStatus(
          message: 'Could not load settings.',
          onRetry: () => ref.invalidate(preferencesControllerProvider),
        ),
        data: (settings) => _ProgressContent(level: settings.level),
      ),
    );
  }
}

class _ProgressContent extends ConsumerWidget {
  const _ProgressContent({required this.level});

  final JlptLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(studyCatalogProvider(level));
    final summary = ref.watch(progressSummaryProvider(level));
    final activity = ref.watch(studyActivityProvider(level));
    final review = ref.watch(reviewCollectionsProvider);
    if (catalog.isLoading || summary.isLoading || activity.isLoading) {
      return const LoadingStatus();
    }
    if (catalog.hasError || summary.hasError || activity.hasError) {
      return ErrorStatus(
        message: 'Your progress could not be loaded.',
        onRetry: () {
          ref.invalidate(studyCatalogProvider(level));
          ref.invalidate(progressSummaryProvider(level));
          ref.invalidate(studyActivityProvider(level));
        },
      );
    }
    final catalogData = catalog.requireValue;
    final summaryData = summary.requireValue;
    final activityData = activity.requireValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TomoSectionLabel('Personal stats'),
        const SizedBox(height: 6),
        Text('Your Progress', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text(
          'Real study activity saved on this device.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TomoSpacing.lg),
        _MetricsGrid(summary: summaryData, activity: activityData),
        const SizedBox(height: TomoSpacing.lg),
        _CurriculumCard(
          level: level,
          catalog: catalogData,
          learned: summaryData.learned,
        ),
        const SizedBox(height: TomoSpacing.lg),
        _WeeklyActivity(activityData),
        const SizedBox(height: TomoSpacing.lg),
        review.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
          data: (collections) => _NeedsReview(
            level: level,
            catalog: catalogData,
            collections: collections,
          ),
        ),
        const SizedBox(height: TomoSpacing.lg),
        _ChapterProgress(catalogData),
        const SizedBox(height: TomoSpacing.lg),
        SurfacePanel(
          padding: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learning totals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${summaryData.learned} studied · ${summaryData.mastered} mastered',
              ),
              Text('${summaryData.lifetimeReviews} lifetime reviews'),
              Text(
                summaryData.lifetimeReviews == 0
                    ? 'Accuracy will appear after your first review.'
                    : '${(summaryData.lifetimeAccuracy * 100).round()}% lifetime correct',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.summary, required this.activity});

  final ProgressSummaryData summary;
  final StudyActivity activity;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 620 ? 4 : 2;
      const gap = TomoSpacing.sm;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      final accuracy = summary.lifetimeReviews == 0
          ? '—'
          : '${(summary.lifetimeAccuracy * 100).round()}%';
      final cards = [
        TomoMetricCard(
          label: 'Words learned',
          value: '${summary.learned}',
          icon: Icons.menu_book_outlined,
          caption: '${summary.learnedToday} new today',
        ),
        TomoMetricCard(
          label: 'Reviews',
          value: '${summary.lifetimeReviews}',
          icon: Icons.sync,
          caption: '${summary.reviewedToday} today',
          color: TomoColors.blue,
        ),
        TomoMetricCard(
          label: 'Streak',
          value: '${activity.streak} ${activity.streak == 1 ? 'day' : 'days'}',
          icon: Icons.local_fire_department,
          caption: '${activity.reviewed} reviews this week',
          color: TomoColors.coral,
        ),
        TomoMetricCard(
          label: 'Review accuracy',
          value: accuracy,
          icon: Icons.pie_chart_outline,
          caption: summary.lifetimeReviews == 0
              ? 'No review history yet'
              : 'Across saved reviews',
          color: TomoColors.amber,
        ),
      ];
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: cards
            .map((card) => SizedBox(width: width, child: card))
            .toList(),
      );
    },
  );
}

class _CurriculumCard extends StatelessWidget {
  const _CurriculumCard({
    required this.level,
    required this.catalog,
    required this.learned,
  });

  final JlptLevel level;
  final StudyCatalog catalog;
  final int learned;

  @override
  Widget build(BuildContext context) {
    final total = catalog.content.vocabulary.length;
    final fraction = total == 0 ? 0.0 : learned / total;
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const TomoIconTile(Icons.military_tech_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JLPT ${level.label} Study Progress',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '$learned of $total unique words studied',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 66,
                height: 66,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: fraction,
                      strokeWidth: 7,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    Text('${(fraction * 100).round()}%'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TomoSpacing.lg),
          ...StudyCategory.values.map((category) {
            final item = catalog.categoryProgress[category]!;
            final color = switch (category) {
              StudyCategory.vocabulary => TomoColors.blue,
              StudyCategory.kanji => TomoColors.coral,
              StudyCategory.grammar => TomoColors.amber,
              StudyCategory.adverbs => TomoColors.success,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(category.label)),
                      Text('${item.learned} / ${item.total}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: item.fraction, color: color),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WeeklyActivity extends StatelessWidget {
  const _WeeklyActivity(this.activity);

  final StudyActivity activity;

  @override
  Widget build(BuildContext context) {
    final largest = max(1, activity.reviewCounts.reduce(max));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Review Activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${activity.reviewed} saved reviews in the last 7 days',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TomoBadge('${activity.streak} day streak'),
            ],
          ),
          const SizedBox(height: TomoSpacing.lg),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final count = activity.reviewCounts[index];
                final today = index == 6;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: count == 0 ? 4 : 80 * count / largest,
                          decoration: BoxDecoration(
                            color: count == 0
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : today
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[activity.days[index].weekday - 1],
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: today
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsReview extends StatelessWidget {
  const _NeedsReview({
    required this.level,
    required this.catalog,
    required this.collections,
  });

  final JlptLevel level;
  final StudyCatalog catalog;
  final ReviewCollections collections;

  @override
  Widget build(BuildContext context) {
    final items = collections.weak
        .map(
          (progress) =>
              (progress, catalog.content.vocabulary[progress.contentId]),
        )
        .where((pair) => pair.$2 != null)
        .take(3)
        .toList();
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TomoIconTile(
                Icons.priority_high,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Needs Review',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Difficult words and recorded mistakes',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TomoBadge(
                '${collections.weak.length} words',
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          if (items.isEmpty) ...[
            const SizedBox(height: TomoSpacing.lg),
            Text(
              'No weak words yet. Difficult flags and review history will appear here.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            const SizedBox(height: TomoSpacing.md),
            ...items.map((pair) {
              final progress = pair.$1;
              final card = pair.$2!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(TomoRadii.control),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TomoRadii.control),
                    ),
                    title: Text(card.word),
                    subtitle: Text('${card.reading} · ${card.meanings.first}'),
                    trailing: Text(
                      progress.incorrectCount == 0
                          ? 'Marked difficult'
                          : '${progress.incorrectCount} ${progress.incorrectCount == 1 ? 'mistake' : 'mistakes'}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () => context.pushNamed(
                      AppRoutes.word,
                      pathParameters: {'level': level.name, 'id': card.id},
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.pushNamed(
                AppRoutes.reviewStudy,
                pathParameters: {'level': level.name, 'filter': 'weak'},
              ),
              icon: const Icon(Icons.school_outlined),
              label: Text('Practice Weak Words (${collections.weak.length})'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress(this.catalog);

  final StudyCatalog catalog;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      shape: const Border(),
      title: const Text('Chapter Progress'),
      subtitle: const Text('See progress across installed chapters'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: catalog.content.decks
          .where((deck) => deck.contentIds.isNotEmpty)
          .map((deck) {
            final progress = catalog.chapterProgress[deck.id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(StudyCatalog.deckTitle(deck))),
                      Text('${progress.learned} / ${progress.total}'),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(value: progress.fraction),
                ],
              ),
            );
          })
          .toList(),
    ),
  );
}
