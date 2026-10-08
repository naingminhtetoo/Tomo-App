import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';
import 'widgets/dashboard_sections.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return TomoScaffold(
      title: 'Tomo',
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.pushNamed(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      child: ref
          .watch(preferencesControllerProvider)
          .when(
            loading: () => const LoadingStatus(),
            error: (_, _) => ErrorStatus(
              message: 'Could not load preferences.',
              onRetry: () => ref.invalidate(preferencesControllerProvider),
            ),
            data: (preferences) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Japanese Study Companion',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'A little practice, every day.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                ContinueStudyCard(level: preferences.level),
                const SizedBox(height: 32),
                Text('Study', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                StudyGrid(level: preferences.level),
                const SizedBox(height: 32),
                ProgressSummary(level: preferences.level),
              ],
            ),
          ),
    );
  }
}
