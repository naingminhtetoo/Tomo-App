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
                _CourseSummary(
                  level: level,
                  category: category,
                  title: selected.title,
                  chapterCount: selected.decks.length,
                  progress: progress,
                  onBack: () => context.pop(),
                  onBrowseAll: () => _browse(context, 'all:$source'),
                ),
                const SizedBox(height: TomoSpacing.md),
                Text(
                  'Course Roadmap',
                  style: Theme.of(context).textTheme.titleLarge,
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
                    padding: const EdgeInsets.only(bottom: TomoSpacing.sm),
                    child: CompactChapterRow(
                      key: Key('chapter-row-${deck.id}'),
                      number: deck.chapter ?? entry.key + 1,
                      title: StudyCatalog.deckTitle(deck),
                      progress: chapterProgress,
                      current: current,
                      onTap: () => _browse(context, deck.id),
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
    required this.onBrowseAll,
  });

  final JlptLevel level;
  final StudyCategory category;
  final String title;
  final int chapterCount;
  final DeckProgress progress;
  final VoidCallback onBack, onBrowseAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SurfacePanel(
      key: const Key('course-summary'),
      padding: TomoSpacing.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                key: const Key('back-to-decks'),
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Decks'),
              ),
              const Spacer(),
              Tooltip(
                message: 'Browse all words in this course',
                child: IconButton(
                  key: const Key('browse-all-words'),
                  onPressed: onBrowseAll,
                  color: scheme.onSurfaceVariant,
                  icon: const Icon(Icons.view_list_outlined, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: TomoSpacing.xs),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TomoSpacing.xs),
          Text(
            '${category.label} · JLPT ${level.label}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            '$chapterCount ${chapterCount == 1 ? 'chapter' : 'chapters'} · ${progress.total} items',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A dense chapter target that keeps the full row interactive.
///
/// It is public so the responsive layout can be exercised with long localized
/// titles independently of the installed content catalog.
class CompactChapterRow extends StatelessWidget {
  const CompactChapterRow({
    super.key,
    required this.number,
    required this.title,
    required this.progress,
    required this.current,
    required this.onTap,
  });

  final int number;
  final String title;
  final DeckProgress progress;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = progress.total > 0;
    final status = enabled
        ? '${progress.learned} / ${progress.total} learned${current ? ' · Continue' : ''}'
        : 'No items';
    return Card(
      color: current ? scheme.surfaceContainerHigh : null,
      child: Semantics(
        button: true,
        enabled: enabled,
        excludeSemantics: true,
        label: 'Chapter ${number.toString().padLeft(2, '0')}, $title, $status',
        child: InkWell(
          borderRadius: BorderRadius.circular(TomoRadii.card),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Opacity(
              opacity: enabled ? 1 : 0.55,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: current
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                          ),
                          if (enabled) ...[
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progress.fraction,
                              minHeight: 3,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      enabled ? Icons.chevron_right : Icons.lock_outline,
                      color: current ? scheme.primary : scheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
