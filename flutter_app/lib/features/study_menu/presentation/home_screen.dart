import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';

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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue Studying',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'JLPT Level: ${preferences.level.label}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton.icon(
                              onPressed: () => context.pushNamed(
                                AppRoutes.study,
                                pathParameters: {
                                  'level': preferences.level.name,
                                },
                              ),
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Open study menu'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.pushNamed(AppRoutes.levels),
                              child: const Text('Change level'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('Study', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 600
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _StudyTile(
                          width: width,
                          title: 'Vocabulary',
                          subtitle: 'Words, readings and meanings',
                          icon: Icons.layers_outlined,
                          onTap: () => context.pushNamed(
                            AppRoutes.study,
                            pathParameters: {'level': preferences.level.name},
                          ),
                        ),
                        _StudyTile(
                          width: width,
                          title: 'Kanji',
                          subtitle: 'Study through vocabulary',
                          icon: Icons.auto_stories_outlined,
                          onTap: () => context.pushNamed(
                            AppRoutes.study,
                            pathParameters: {'level': preferences.level.name},
                          ),
                        ),
                        _StudyTile(
                          width: width,
                          title: 'Grammar',
                          subtitle: 'Coming in a later phase',
                          icon: Icons.menu_book_outlined,
                        ),
                        _StudyTile(
                          width: width,
                          title: 'Review',
                          subtitle: 'Review system coming soon',
                          icon: Icons.history,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Progress',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pushNamed(AppRoutes.progress),
                      child: const Text('View progress'),
                    ),
                  ],
                ),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Wrap(
                      spacing: 32,
                      runSpacing: 16,
                      children: [
                        _ProgressStat(label: 'Reviewed today'),
                        _ProgressStat(label: 'Learning'),
                        _ProgressStat(label: 'Mastered'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your progress will appear here when tracking is available.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _StudyTile extends StatelessWidget {
  const _StudyTile({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      ),
    ),
  );
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('—', style: Theme.of(context).textTheme.headlineSmall),
      Text(label),
    ],
  );
}
