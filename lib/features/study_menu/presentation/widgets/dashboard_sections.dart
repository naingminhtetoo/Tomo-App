import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/tomo_theme.dart';
import '../../../../core/widgets/tomo_components.dart';
import '../../../../core/widgets/tomo_scaffold.dart';
import '../../../level_selection/data/app_preferences.dart';
import '../../../level_selection/domain/jlpt_level.dart';
import '../../../progress/presentation/progress_providers.dart';
import '../../domain/study_catalog.dart';
import '../catalog_provider.dart';

IconData categoryIcon(StudyCategory category) => switch (category) {
  StudyCategory.vocabulary => Icons.translate,
  StudyCategory.kanji => Icons.edit_note,
  StudyCategory.grammar => Icons.menu_book_outlined,
  StudyCategory.adverbs => Icons.chat_bubble_outline,
};

String categoryDescription(StudyCategory category) => switch (category) {
  StudyCategory.vocabulary => 'Words & meanings',
  StudyCategory.kanji => 'Readings & examples',
  StudyCategory.grammar => 'Patterns & usage',
  StudyCategory.adverbs => 'Expressions',
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
    final session = ref.watch(activeSessionProvider).value;
    final catalog = ref.watch(studyCatalogProvider(level)).value;
    final browse = lastLearning?.level == level ? lastLearning : null;
    final category = StudyCategory.tryParse(browse?.category);
    final source = catalog == null || category == null
        ? null
        : catalog
              .sources(category)
              .where((item) => item.id == browse?.source)
              .firstOrNull;
    final deck = catalog?.content.decks
        .where((item) => item.id == browse?.deckId)
        .firstOrNull;
    final canContinueLearning =
        browse != null &&
        category != null &&
        source != null &&
        (browse.deckId.startsWith('all:') || deck != null);

    if (!canContinueLearning && session == null) {
      return const SizedBox.shrink();
    }

    final title = canContinueLearning
        ? deck == null
              ? source.title
              : StudyCatalog.deckTitle(deck)
        : 'Resume Flashcards';
    final subtitle = canContinueLearning
        ? '${category.label} · ${source.title}'
        : 'Card ${session!.currentIndex + 1} of ${session.contentIds.length}';

    void openPrimary() {
      if (canContinueLearning) {
        context.pushNamed(
          AppRoutes.learningList,
          pathParameters: {'level': browse.level.name, 'kind': browse.category},
          queryParameters: {'source': browse.source, 'deck': browse.deckId},
        );
      } else {
        context.pushNamed(
          AppRoutes.session,
          pathParameters: {'level': session!.level},
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: TomoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pick up where you left off',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TomoSpacing.sm),
          Card(
            child: Column(
              children: [
                InkWell(
                  key: const Key('continue-learning-card'),
                  borderRadius: BorderRadius.circular(TomoRadii.card),
                  onTap: openPrimary,
                  child: Padding(
                    padding: const EdgeInsets.all(TomoSpacing.md),
                    child: Row(
                      children: [
                        TomoIconTile(
                          canContinueLearning
                              ? categoryIcon(category)
                              : Icons.style_outlined,
                        ),
                        const SizedBox(width: TomoSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: TomoSpacing.sm),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
                if (canContinueLearning && session != null) ...[
                  Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('resume-flashcards'),
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
          ),
        ],
      ),
    );
  }
}

class ProgressSummary extends ConsumerWidget {
  const ProgressSummary({super.key, required this.level});

  final JlptLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider(level));
    final activity = ref.watch(studyActivityProvider(level));
    final progress = summary.value;
    final weekly = activity.value;

    return Padding(
      padding: const EdgeInsets.only(top: TomoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Today's Learning",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TomoSpacing.sm),
          SurfacePanel(
            padding: TomoSpacing.md,
            child: progress == null || weekly == null
                ? summary.hasError || activity.hasError
                      ? const Text('Today’s learning could not be loaded.')
                      : const LinearProgressIndicator()
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              key: const Key('learned-today-stat'),
                              value: '${progress.learnedToday}',
                              label: 'Words learned',
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              key: const Key('reviewed-today-stat'),
                              value: '${progress.reviewedToday}',
                              label: 'Reviews',
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              key: const Key('streak-stat'),
                              value: '${weekly.streak}',
                              label: 'Day streak',
                              accent: weekly.streak > 0,
                            ),
                          ),
                        ],
                      ),
                      if (progress.learnedToday == 0 &&
                          progress.reviewedToday == 0 &&
                          weekly.streak == 0) ...[
                        const SizedBox(height: TomoSpacing.sm),
                        Text(
                          'Choose any topic above when you are ready to begin.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: accent ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
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
        error: (_, _) => const SizedBox.shrink(),
        data: (summary) {
          if (summary.dueCount == 0) return const SizedBox.shrink();
          final noun = summary.dueCount == 1 ? 'word' : 'words';
          return Padding(
            padding: const EdgeInsets.only(top: TomoSpacing.md),
            child: Card(
              child: InkWell(
                key: const Key('home-review-reminder'),
                borderRadius: BorderRadius.circular(TomoRadii.card),
                onTap: () => context.go('/review'),
                child: Padding(
                  padding: const EdgeInsets.all(TomoSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: TomoSpacing.md),
                      Expanded(
                        child: Text(
                          '${summary.dueCount} $noun ready for review',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
            const gap = TomoSpacing.sm;
            final width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: StudyCategory.values.map((category) {
                final progress = catalog.categoryProgress[category]!;
                final available = progress.total > 0;
                return SizedBox(
                  width: width,
                  child: Semantics(
                    button: available,
                    enabled: available,
                    label:
                        '${category.label}. ${categoryDescription(category)}. ${available ? 'Available' : 'Not installed'}',
                    child: Card(
                      child: InkWell(
                        key: Key('home-category-${category.name}'),
                        borderRadius: BorderRadius.circular(TomoRadii.card),
                        onTap: available
                            ? () => context.pushNamed(
                                AppRoutes.category,
                                pathParameters: {
                                  'level': level.name,
                                  'kind': category.name,
                                },
                              )
                            : null,
                        child: Opacity(
                          opacity: available ? 1 : 0.58,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 148),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        categoryIcon(category),
                                        color: available
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                      ),
                                      const Spacer(),
                                      Icon(
                                        available
                                            ? Icons.arrow_outward
                                            : Icons.lock_outline,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: TomoSpacing.md),
                                  Text(
                                    category.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    categoryDescription(category),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: TomoSpacing.sm),
                                  Text(
                                    available
                                        ? 'Available offline'
                                        : 'Not installed',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: available
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
