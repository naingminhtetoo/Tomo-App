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
import '../../progress/presentation/progress_providers.dart';
import '../domain/study_catalog.dart';
import 'catalog_provider.dart';

class ChapterScreen extends ConsumerWidget {
  const ChapterScreen({
    super.key,
    required this.level,
    required this.category,
    required this.source,
  });

  final JlptLevel level;
  final StudyCategory category;
  final String source;

  void _browse(BuildContext context, String deckId) => context.pushNamed(
    AppRoutes.learningList,
    pathParameters: {'level': level.name, 'kind': category.name},
    queryParameters: {'deck': deckId, 'source': source},
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'Chapter selection',
    brandHeader: true,
    sectionLabel: 'Study',
    levelLabel: level.label,
    maxContentWidth: 640,
    child: ref
        .watch(studyCatalogProvider(level))
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => ErrorStatus(
            message: 'Chapters could not be loaded.',
            onRetry: () => ref.invalidate(studyCatalogProvider(level)),
          ),
          data: (catalog) {
            final selected = catalog
                .sources(category)
                .where((candidate) => candidate.id == source)
                .firstOrNull;
            if (selected == null || selected.contentIds.isEmpty) {
              return const TomoEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No chapters installed',
                message: 'This source has no local chapters yet.',
              );
            }
            final progress =
                catalog.sourceProgress['${category.name}/$source']!;
            final active = ref.watch(activeSessionProvider).value;
            final activeId = active == null || active.contentIds.isEmpty
                ? null
                : active.contentIds[active.currentIndex];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chapter selection',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TomoSpacing.sm),
                _CourseSummary(
                  level: level,
                  category: category,
                  title: selected.title,
                  chapterCount: selected.decks.length,
                  progress: progress,
                  onBack: () => context.pop(),
                ),
                const SizedBox(height: TomoSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Course Roadmap',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TomoBadge(
                      '${selected.decks.length} ${selected.decks.length == 1 ? 'unit' : 'units'}',
                      accent: false,
                    ),
                  ],
                ),
                const SizedBox(height: TomoSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _browse(context, 'all:$source'),
                    icon: const Icon(Icons.view_list_outlined),
                    label: const Text('Browse All Words'),
                  ),
                ),
                const SizedBox(height: TomoSpacing.md),
                ...selected.decks.asMap().entries.map((entry) {
                  final deck = entry.value;
                  final chapterProgress = catalog.chapterProgress[deck.id]!;
                  final current =
                      active?.level == level.name &&
                      (active?.deckId == deck.id ||
                          (active?.deckId == 'all:$source' &&
                              activeId != null &&
                              deck.contentIds.contains(activeId)));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: TomoSpacing.md),
                    child: _ChapterCard(
                      number: deck.chapter ?? entry.key + 1,
                      title: StudyCatalog.deckTitle(deck),
                      progress: chapterProgress,
                      current: current,
                      onBrowse: () => _browse(context, deck.id),
                    ),
                  );
                }),
              ],
            );
          },
        ),
  );
}

class _CourseSummary extends StatelessWidget {
  const _CourseSummary({
    required this.level,
    required this.category,
    required this.title,
    required this.chapterCount,
    required this.progress,
    required this.onBack,
  });

  final JlptLevel level;
  final StudyCategory category;
  final String title;
  final int chapterCount;
  final DeckProgress progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SurfacePanel(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TomoSpacing.sm,
            runSpacing: TomoSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Decks'),
              ),
              TomoBadge(category.label, accent: false),
            ],
          ),
          const SizedBox(height: TomoSpacing.sm),
          Text(
            'JLPT ${level.label} — $title',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: TomoSpacing.sm),
          Text(
            '$chapterCount local ${chapterCount == 1 ? 'chapter' : 'chapters'} · ${progress.total} unique words',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: TomoSpacing.lg),
          Row(
            children: [
              Icon(Icons.verified_outlined, color: scheme.secondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${progress.learned} of ${progress.total} words studied',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '${(progress.fraction * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: progress.fraction),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.number,
    required this.title,
    required this.progress,
    required this.current,
    required this.onBrowse,
  });

  final int number;
  final String title;
  final DeckProgress progress;
  final bool current;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final complete = progress.total > 0 && progress.learned == progress.total;
    final started = progress.learned > 0;
    final status = current
        ? 'CURRENT'
        : complete
        ? 'STUDIED'
        : started
        ? 'IN PROGRESS'
        : 'READY';
    final statusColor = current
        ? scheme.primary
        : complete
        ? TomoColors.blue
        : started
        ? TomoColors.amber
        : scheme.onSurfaceVariant;
    return Card(
      color: current ? scheme.surfaceContainerHigh : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(TomoRadii.card),
        onTap: progress.total == 0 ? null : onBrowse,
        child: Stack(
          children: [
            if (current)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    color: TomoColors.coral,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(TomoRadii.card),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(TomoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: current
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          number.toString().padLeft(2, '0'),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: current ? scheme.onPrimary : null,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${progress.total} words',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TomoBadge(status, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: TomoSpacing.md),
                  if (started || current) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${progress.learned}/${progress.total} studied',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Text(
                          '${progress.total - progress.learned} to go',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: current
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress.fraction),
                    const SizedBox(height: TomoSpacing.md),
                  ],
                  Row(
                    children: [
                      Icon(
                        complete
                            ? Icons.verified_outlined
                            : current
                            ? Icons.local_fire_department_outlined
                            : Icons.menu_book_outlined,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          complete
                              ? 'Ready to review'
                              : current
                              ? 'Saved session available'
                              : 'Ready to study',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TomoSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: progress.total == 0 ? null : onBrowse,
                      icon: const Icon(Icons.chevron_right),
                      iconAlignment: IconAlignment.end,
                      label: const Text('Browse Words'),
                    ),
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
