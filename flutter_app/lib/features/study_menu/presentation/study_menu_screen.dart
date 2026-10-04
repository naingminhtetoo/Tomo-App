import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/domain/entities/deck_category.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';

class StudyMenuScreen extends ConsumerWidget {
  const StudyMenuScreen({super.key, required this.level});
  final JlptLevel level;
  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: '${level.label} · Study menu',
    child: ref
        .watch(levelContentProvider(level))
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => ErrorStatus(
            message:
                'No usable local content could be loaded for ${level.label}.',
            onRetry: () => ref.invalidate(levelContentProvider(level)),
          ),
          data: (snapshot) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a collection',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text('Flashcard practice is coming in a later phase.'),
              const SizedBox(height: 24),
              ...DeckCategory.values.map((category) {
                final count = snapshot.content.cards(category).length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      title: Text(category.label),
                      subtitle: Text(
                        count == 0 ? 'Content coming soon' : '$count cards',
                      ),
                      enabled: count > 0,
                      trailing: count > 0
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap: count > 0
                          ? () => context.pushNamed(
                              AppRoutes.deck,
                              pathParameters: {
                                'level': level.name,
                                'category': category.contentKey,
                              },
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
  );
}
