import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../../core/widgets/async_status.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../domain/study_catalog.dart';
import '../../vocabulary/domain/entities/deck_category.dart';
import 'catalog_provider.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({
    super.key,
    required this.level,
    required this.category,
  });
  final JlptLevel level;
  final StudyCategory category;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: category.label,
    levelLabel: level.label,
    child: ref
        .watch(studyCatalogProvider(level))
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => ErrorStatus(
            message: 'Local sources could not be loaded.',
            onRetry: () => ref.invalidate(studyCatalogProvider(level)),
          ),
          data: (catalog) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TomoBadge('JLPT ${level.label}'),
              const SizedBox(height: 16),
              Text(
                '${category.label} ${category.japanese}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                category == StudyCategory.kanji
                    ? 'Kanji through the supplied vocabulary collections'
                    : 'Choose a study source',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (catalog.categoryProgress[category]!.total == 0)
                SurfacePanel(
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'No ${category.label.toLowerCase()} content installed yet.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Available N2 vocabulary collections can be studied offline.',
                      ),
                    ],
                  ),
                ),
              ...catalog
                  .sources(category)
                  .where((source) => source.contentIds.isNotEmpty)
                  .map((source) {
                    final progress = catalog
                        .sourceProgress['${category.name}/${source.id}']!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(24),
                          title: Text(
                            source.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${source.decks.length} chapters · ${progress.total} cards',
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: progress.fraction,
                                ),
                                const SizedBox(height: 8),
                                Text('${progress.learned} learned'),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            if (source.decks.length == 1) {
                              final deck = source.decks.single;
                              context.pushNamed(
                                AppRoutes.deck,
                                pathParameters: {
                                  'level': level.name,
                                  'category':
                                      (DeckCategory.tryParse(deck.category) ??
                                              DeckCategory.other)
                                          .contentKey,
                                },
                                queryParameters: {
                                  'deck': deck.id,
                                  'source': source.id,
                                  'start': '1',
                                },
                              );
                              return;
                            }
                            context.pushNamed(
                              AppRoutes.chapters,
                              pathParameters: {
                                'level': level.name,
                                'kind': category.name,
                                'source': source.id,
                              },
                            );
                          },
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
  );
}
