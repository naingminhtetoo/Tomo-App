import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';
import 'catalog_provider.dart';
import 'widgets/dashboard_sections.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider);
    return TomoScaffold(
      title: 'Tomo',
      brandHeader: true,
      levelLabel: preferences.value?.level.label,
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.pushNamed(AppRoutes.settings),
          icon: const Icon(Icons.person_outline),
        ),
        const SizedBox(width: 16),
      ],
      child: preferences.when(
        loading: () => const LoadingStatus(),
        error: (_, _) => ErrorStatus(
          message: 'Could not load preferences.',
          onRetry: () => ref.invalidate(preferencesControllerProvider),
        ),
        data: (settings) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.levels),
                  icon: const Icon(Icons.expand_more),
                  iconAlignment: IconAlignment.end,
                  label: Text('JLPT ${settings.level.label} · Change Level'),
                ),
                ref
                    .watch(studyActivityProvider(settings.level))
                    .when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (activity) =>
                          TomoBadge('${activity.streak} day streak'),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome back. Ready for your daily practice?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            ContinueStudyCard(
              level: settings.level,
              lastLearning: settings.lastLearning,
            ),
            const SizedBox(height: 24),
            ProgressSummary(level: settings.level),
            const SizedBox(height: 24),
            DailyReviewCard(level: settings.level),
            const SizedBox(height: 30),
            SectionHeading(
              'Study Categories',
              trailing: TextButton(
                onPressed: () => context.pushNamed(
                  AppRoutes.study,
                  pathParameters: {'level': settings.level.name},
                ),
                child: const Text('See all ›'),
              ),
            ),
            StudyGrid(level: settings.level),
            const SizedBox(height: 28),
            SurfacePanel(
              padding: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAILY LEARNING TIP'),
                        SizedBox(height: 8),
                        Text(
                          'A short, focused session is a good place to start. Reveal the answer, then rate how well you remembered it.',
                        ),
                      ],
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
