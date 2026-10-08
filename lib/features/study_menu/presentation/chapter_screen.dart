import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../../core/widgets/async_status.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../progress/presentation/progress_providers.dart';
import '../../vocabulary/domain/entities/deck_category.dart';
import '../../vocabulary/domain/entities/study_deck.dart';
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
  void _study(BuildContext context, StudyDeck deck, String id) =>
      context.pushNamed(
        AppRoutes.deck,
        pathParameters: {
          'level': level.name,
          'category':
              (DeckCategory.tryParse(deck.category) ?? DeckCategory.other)
                  .contentKey,
        },
        queryParameters: {'deck': id, 'source': source, 'start': '1'},
      );
  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'Chapter selection',
    levelLabel: level.label,
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
                .where((s) => s.id == source)
                .firstOrNull;
            if (selected == null || selected.contentIds.isEmpty) {
              return const SurfacePanel(
                child: Text('This source has no installed chapters.'),
              );
            }
            final progress =
                catalog.sourceProgress['${category.name}/$source']!;
            final active = ref.watch(activeSessionProvider).value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TomoBadge('JLPT ${level.label}'),
                const SizedBox(height: 16),
                Text(
                  selected.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '${selected.decks.length} chapters · ${progress.total} unique items',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SurfacePanel(
                  padding: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('OVERALL PROGRESS'),
                            const SizedBox(height: 8),
                            Text(
                              '${progress.learned} / ${progress.total} learned',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress.fraction,
                              strokeWidth: 4,
                            ),
                            Text('${(progress.fraction * 100).round()}%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        _study(context, selected.decks.first, 'all:$source'),
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('Study All Chapters'),
                  ),
                ),
                const SizedBox(height: 24),
                ...selected.decks.asMap().entries.map((entry) {
                  final deck = entry.value;
                  final p = catalog.chapterProgress[deck.id]!;
                  final current =
                      active?.deckId == deck.id && active?.level == level.name;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SurfacePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'CHAPTER ${(deck.chapter ?? entry.key + 1).toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      letterSpacing: 1,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              TomoBadge(
                                current
                                    ? 'Current'
                                    : p.total > 0 && p.learned == p.total
                                    ? 'Completed'
                                    : p.learned > 0
                                    ? 'In Progress'
                                    : 'Not started',
                                accent: current || p.learned > 0,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            StudyCatalog.deckTitle(deck),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(child: Text('Learned items')),
                              Text('${p.learned} / ${p.total}'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(value: p.fraction),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: p.total == 0
                                  ? null
                                  : () => _study(context, deck, deck.id),
                              icon: const Icon(Icons.chevron_right),
                              iconAlignment: IconAlignment.end,
                              label: Text(
                                current ? 'Continue Chapter' : 'Start Chapter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
  );
}
