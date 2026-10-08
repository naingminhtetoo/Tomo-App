import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../../core/widgets/async_status.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import '../../vocabulary/domain/entities/vocabulary_card.dart';
import '../domain/study_catalog.dart';
import 'catalog_provider.dart';
import 'widgets/dashboard_sections.dart';

final localSearchProvider = FutureProvider.autoDispose
    .family<List<VocabularyCard>, ({JlptLevel level, String query})>(
      (ref, key) async => (await ref.watch(
        levelContentProvider(key.level).future,
      )).content.search(key.query),
    );

class StudyMenuScreen extends ConsumerStatefulWidget {
  const StudyMenuScreen({super.key, required this.level});
  final JlptLevel level;
  @override
  ConsumerState<StudyMenuScreen> createState() => _StudyMenuState();
}

class _StudyMenuState extends ConsumerState<StudyMenuScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) => TomoScaffold(
    title: 'Study',
    brandHeader: true,
    levelLabel: widget.level.label,
    child: ref
        .watch(studyCatalogProvider(widget.level))
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => ErrorStatus(
            message: 'No local content is available for ${widget.level.label}.',
            onRetry: () => ref.invalidate(studyCatalogProvider(widget.level)),
          ),
          data: (catalog) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study — ${widget.level.label}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a category and textbook track',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('local-search'),
                decoration: const InputDecoration(
                  labelText: 'Search local words',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 24),
              if (_query.trim().isNotEmpty)
                ref
                    .watch(
                      localSearchProvider((level: widget.level, query: _query)),
                    )
                    .when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) =>
                          const Text('Local search could not be loaded.'),
                      data: (cards) => Column(
                        children: [
                          if (cards.isEmpty)
                            const SurfacePanel(
                              child: Text('No matching words.'),
                            ),
                          ...cards.map(
                            (card) => ListTile(
                              title: Text(card.word),
                              subtitle: Text(
                                '${card.reading} · ${card.meanings.join('; ')}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.pushNamed(
                                AppRoutes.word,
                                pathParameters: {
                                  'level': widget.level.name,
                                  'id': card.id,
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
              else
                ...StudyCategory.values.map((category) {
                  final progress = catalog.categoryProgress[category]!;
                  final sources = catalog.sources(category);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => context.pushNamed(
                          AppRoutes.category,
                          pathParameters: {
                            'level': widget.level.name,
                            'kind': category.name,
                          },
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    categoryIcon(category),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      category.label,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                  ),
                                  Text(
                                    category.japanese,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                progress.total == 0
                                    ? 'No content installed yet'
                                    : sources.map((s) => s.title).join(' · '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${progress.learned} / ${progress.total} learned',
                                    ),
                                  ),
                                  TomoBadge(
                                    '${(progress.fraction * 100).round()}%',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(value: progress.fraction),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
  );
}
