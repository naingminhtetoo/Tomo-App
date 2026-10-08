import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import 'progress_providers.dart';
import '../domain/progress_repository.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'Daily Review',
    child: ref
        .watch(reviewCollectionsProvider)
        .when(
          loading: () => const CircularProgressIndicator(),
          error: (_, _) => const Text('Could not load review data.'),
          data: (data) => Column(
            children: [
              _section(ref, 'Due Today', data.due),
              _section(ref, 'Weak Words', data.weak),
              _section(ref, 'Favorites', data.favorites),
              _section(ref, 'Recently Learned', data.recent),
              _section(ref, 'Common Mistakes', data.mistakes),
            ],
          ),
        ),
  );
  Widget _section(
    WidgetRef ref,
    String title,
    List<StudyProgress> items,
  ) => ExpansionTile(
    title: Text(title),
    subtitle: Text('${items.length} items'),
    children: [
      if (items.isEmpty) const ListTile(title: Text('No items yet.')),
      ...items.map((p) {
        // Resolve display text locally; stale IDs remain preserved in SQLite.
        final word = ref
            .watch(levelContentProvider(JlptLevel.n2))
            .value
            ?.content
            .vocabulary[p.contentId];
        return ListTile(
          title: Text(word?.word ?? p.contentId),
          subtitle: Text(word?.reading ?? 'Content is not installed'),
          trailing: IconButton(
            tooltip: 'Favorite',
            icon: Icon(p.favorite ? Icons.star : Icons.star_outline),
            onPressed: () => ref
                .read(progressRepositoryProvider)
                .toggleFavorite(p.contentId, type: p.contentType),
          ),
        );
      }),
    ],
  );
}
