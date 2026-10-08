import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../../study_menu/domain/study_catalog.dart';
import '../../study_menu/presentation/catalog_provider.dart';
import '../domain/progress_repository.dart';
import 'progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider);
    return TomoScaffold(
      title: 'Progress',
      brandHeader: true,
      levelLabel: preferences.value?.level.label,
      child: preferences.when(
        loading: () => const CircularProgressIndicator(),
        error: (_, _) => const Text('Could not load settings.'),
        data: (settings) {
          final catalog = ref.watch(studyCatalogProvider(settings.level));
          final summary = ref.watch(progressSummaryProvider(settings.level));
          final activity = ref.watch(studyActivityProvider(settings.level));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: TomoBadge('PROGRESS & MASTERY'),
              ),
              const SizedBox(height: 10),
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              const Text('Keep going — every word counts.'),
              const SizedBox(height: 26),
              activity.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Activity could not be loaded.'),
                data: (a) => Column(
                  children: [
                    SurfacePanel(
                      accent: true,
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              TomoBadge('JLPT ${settings.level.label}'),
                              TomoBadge(
                                '${a.streak} day streak',
                                accent: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _stat(
                                  context,
                                  '${a.reviewed}',
                                  'reviews this week',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _stat(
                                  context,
                                  a.reviewed == 0
                                      ? '—'
                                      : '${(a.accuracy * 100).round()}%',
                                  'correct this week',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _rhythm(context, a),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionHeading('Curriculum Progress'),
              catalog.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Curriculum could not be loaded.'),
                data: (c) => Column(
                  children: [
                    ...StudyCategory.values.map((category) {
                      final p = c.categoryProgress[category]!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: SurfacePanel(
                          padding: 20,
                          child: InkWell(
                            onTap: () => context.pushNamed(
                              AppRoutes.category,
                              pathParameters: {
                                'level': settings.level.name,
                                'kind': category.name,
                              },
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${category.japanese}  ${category.label}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    Text('${p.learned} / ${p.total}'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(value: p.fraction),
                                const SizedBox(height: 10),
                                Text(
                                  p.total == 0
                                      ? 'No installed content'
                                      : '${(p.fraction * 100).round()}% studied',
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const SectionHeading('Chapter Progress'),
                    ...c.content.decks
                        .where((d) => d.contentIds.isNotEmpty)
                        .map((d) {
                          final p = c.chapterProgress[d.id]!;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SurfacePanel(
                              padding: 18,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    StudyCatalog.deckTitle(d),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${p.learned} / ${p.total} words studied',
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(value: p.fraction),
                                ],
                              ),
                            ),
                          );
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              summary.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) =>
                    const Text('Review totals could not be loaded.'),
                data: (s) => SurfacePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learning totals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text('${s.learned} studied · ${s.mastered} mastered'),
                      Text('${s.lifetimeReviews} lifetime reviews'),
                      Text(
                        s.lifetimeReviews == 0
                            ? 'Accuracy will appear after your first review.'
                            : '${(s.lifetimeAccuracy * 100).round()}% lifetime correct',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 4),
      Text(label),
    ],
  );
  Widget _rhythm(BuildContext context, StudyActivity a) {
    final largest = max(1, a.reviewCounts.reduce(max));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Rhythm', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Reviews across the last 7 days'),
          const SizedBox(height: 24),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                7,
                (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${a.reviewCounts[i]}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 7),
                        Container(
                          height: a.reviewCounts[i] == 0
                              ? 4
                              : 76 * a.reviewCounts[i] / largest,
                          decoration: BoxDecoration(
                            color: a.reviewCounts[i] == 0
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(labels[a.days[i].weekday - 1]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
