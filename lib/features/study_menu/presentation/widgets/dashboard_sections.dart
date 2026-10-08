import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../progress/presentation/progress_providers.dart';
import '../../../vocabulary/presentation/vocabulary_controller.dart';
import '../../../vocabulary/domain/entities/deck_category.dart';

import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../level_selection/domain/jlpt_level.dart';

class ContinueStudyCard extends ConsumerWidget {
  const ContinueStudyCard({super.key, required this.level});
  final JlptLevel level;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Continue Studying', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'JLPT Level: ${level.label}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.pushNamed(
                    AppRoutes.study,
                    pathParameters: {'level': level.name},
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Open study menu'),
                ),
                if (ref.watch(activeSessionProvider).value case final session?)
                  FilledButton.tonal(
                    onPressed: () async {
                      final activeLevel = JlptLevel.tryParse(session.level);
                      if (activeLevel == null) return;
                      final snapshot = await ref.read(
                        levelContentProvider(activeLevel).future,
                      );
                      final decks = snapshot.content.decks.where(
                        (d) => d.id == session.deckId,
                      );
                      if (!context.mounted || decks.isEmpty) return;
                      context.pushNamed(
                        AppRoutes.deck,
                        pathParameters: {
                          'level': activeLevel.name,
                          'category':
                              (DeckCategory.tryParse(decks.first.category) ??
                                      DeckCategory.other)
                                  .contentKey,
                        },
                        queryParameters: {'deck': session.deckId},
                      );
                    },
                    child: Text('Resume · card ${session.currentIndex + 1}'),
                  ),
                TextButton(
                  onPressed: () => context.pushNamed(AppRoutes.levels),
                  child: const Text('Change level'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StudyGrid extends StatelessWidget {
  const StudyGrid({super.key, required this.level});
  final JlptLevel level;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 600
          ? (constraints.maxWidth - 16) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _StudyTile(
            width: width,
            title: 'Vocabulary',
            subtitle: 'Words, readings and meanings',
            icon: Icons.layers_outlined,
            onTap: () => context.pushNamed(
              AppRoutes.study,
              pathParameters: {'level': level.name},
            ),
          ),
          _StudyTile(
            width: width,
            title: 'Kanji',
            subtitle: 'Study through vocabulary',
            icon: Icons.auto_stories_outlined,
            onTap: () => context.pushNamed(
              AppRoutes.study,
              pathParameters: {'level': level.name},
            ),
          ),
          _StudyTile(
            width: width,
            title: 'Grammar',
            subtitle: 'Coming in a later phase',
            icon: Icons.menu_book_outlined,
          ),
          _StudyTile(
            width: width,
            title: 'Adverbs',
            subtitle: 'Study local adverb collections',
            icon: Icons.history,
            onTap: () => context.pushNamed(
              AppRoutes.study,
              pathParameters: {'level': level.name},
            ),
          ),
        ],
      );
    },
  );
}

class ProgressSummary extends ConsumerWidget {
  const ProgressSummary({super.key, required this.level});
  final JlptLevel level;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Progress', style: theme.textTheme.titleLarge),
            ),
            TextButton(
              onPressed: () => context.pushNamed(AppRoutes.progress),
              child: const Text('View progress'),
            ),
          ],
        ),
        ref
            .watch(progressSummaryProvider(level))
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Progress could not be loaded.'),
              data: (summary) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 32,
                    runSpacing: 16,
                    children: [
                      _ProgressStat(
                        label: 'Reviewed today',
                        value: '${summary.reviewedToday}',
                      ),
                      _ProgressStat(
                        label: 'Learned today',
                        value: '${summary.learnedToday}',
                      ),
                      _ProgressStat(
                        label: 'Accuracy today',
                        value: summary.totalReviews == 0
                            ? '—'
                            : '${(summary.accuracy * 100).round()}%',
                      ),
                      _ProgressStat(
                        label: 'Due now',
                        value: '${summary.dueCount}',
                      ),
                      _ProgressStat(
                        label: 'Learning',
                        value: '${summary.learning}',
                      ),
                      _ProgressStat(
                        label: 'Mastered',
                        value: '${summary.mastered}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _StudyTile extends StatelessWidget {
  const _StudyTile({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    ),
  );
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
      Text(label),
    ],
  );
}
