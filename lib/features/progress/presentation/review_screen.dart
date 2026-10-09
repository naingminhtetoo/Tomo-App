import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/tomo_theme.dart';
import '../../../core/widgets/tomo_components.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../level_selection/domain/jlpt_level.dart';
import 'progress_providers.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(reviewCollectionsProvider);
    return TomoScaffold(
      title: 'Daily Review',
      brandHeader: true,
      sectionLabel: 'Review',
      levelLabel: data.value?.level.label,
      maxContentWidth: 640,
      child: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const SurfacePanel(child: Text('Could not load review data.')),
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TomoSectionLabel('Review queue'),
            const SizedBox(height: 6),
            Text(
              'Daily Review',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Saved learning history and smart collections',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            SurfacePanel(
              accent: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: TomoIconTile(Icons.update, size: 48),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '${data.due.length} Words Due Today',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.due.isEmpty
                        ? 'Your queue is clear. Study a chapter or revisit a saved collection.'
                        : 'Revisit words with a saved due date and record how well you remember them.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: data.due.isEmpty
                        ? null
                        : () => _start(context, data.level, 'due'),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Start Review'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const SectionHeading('Smart Collections'),
            _collection(
              context,
              data.level,
              'weak',
              'Weak Words',
              'Difficult flags, latest Again / Hard, or repeated errors',
              data.weak.length,
              Icons.heart_broken_outlined,
            ),
            _collection(
              context,
              data.level,
              'favorites',
              'Favorites',
              'Your personal saved vocabulary',
              data.favorites.length,
              Icons.star_outline,
            ),
            _collection(
              context,
              data.level,
              'recent',
              'Recently Learned',
              'Your studied words, newest first',
              data.recent.length,
              Icons.menu_book_outlined,
            ),
            _collection(
              context,
              data.level,
              'mistakes',
              'Common Mistakes',
              'Words with recorded incorrect reviews',
              data.mistakes.length,
              Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 12),
            const SurfacePanel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Build a daily rhythm\nA short review gives you another chance to recall words. Ratings are saved locally without automatic scheduling.',
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

  void _start(BuildContext context, JlptLevel level, String filter) =>
      context.pushNamed(
        AppRoutes.reviewStudy,
        pathParameters: {'level': level.name, 'filter': filter},
      );
  Widget _collection(
    BuildContext context,
    JlptLevel level,
    String filter,
    String title,
    String description,
    int count,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: SurfacePanel(
      padding: 8,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: TomoIconTile(
          icon,
          color: filter == 'weak'
              ? Theme.of(context).colorScheme.error
              : filter == 'recent'
              ? TomoColors.blue
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text('$count words · $description'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _start(context, level, filter),
      ),
    ),
  );
}
