import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/tomo_theme.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';
import 'widgets/dashboard_sections.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider);
    return TomoScaffold(
      title: 'Tomo',
      brandHeader: true,
      showBrandLevel: false,
      levelLabel: preferences.value?.level.label,
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.pushNamed(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
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
            OutlinedButton.icon(
              onPressed: () => context.pushNamed(AppRoutes.levels),
              icon: const Icon(Icons.expand_more),
              iconAlignment: IconAlignment.end,
              label: Text('JLPT ${settings.level.label} · Change Level'),
            ),
            const SizedBox(height: TomoSpacing.lg),
            Text(
              'What will you learn today?',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: TomoSpacing.xs),
            Text(
              'Choose a topic and continue your Japanese learning journey.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TomoSpacing.lg),
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
            ContinueStudyCard(
              level: settings.level,
              lastLearning: settings.lastLearning,
            ),
            DailyReviewCard(level: settings.level),
            ProgressSummary(level: settings.level),
          ],
        ),
      ),
    );
  }
}
