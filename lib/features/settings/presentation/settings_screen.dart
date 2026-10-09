import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tomo_theme.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_components.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../../core/widgets/ui_action.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../level_selection/presentation/level_catalog_controller.dart';
import '../../vocabulary/domain/entities/level_content.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import 'preferences_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider);
    return TomoScaffold(
      title: 'Settings',
      showNavigation: false,
      levelLabel: preferences.value?.level.label,
      maxContentWidth: 640,
      child: preferences.when(
        loading: () => const LoadingStatus(),
        error: (_, _) => ErrorStatus(
          message: 'Could not load preferences.',
          onRetry: () => ref.invalidate(preferencesControllerProvider),
        ),
        data: (settings) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SurfacePanel(
              accent: true,
              child: Row(
                children: [
                  const TomoIconTile(Icons.tune, size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study preferences',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Customize your local Tomo experience',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TomoBadge('JLPT ${settings.level.label}'),
                ],
              ),
            ),
            const SizedBox(height: TomoSpacing.lg),
            const TomoSectionLabel('Study target & rhythm'),
            const SizedBox(height: TomoSpacing.sm),
            _LevelSelector(selected: settings.level),
            const SizedBox(height: TomoSpacing.sm),
            _SettingsGroup(
              children: [
                SwitchListTile(
                  key: const Key('shuffle-switch'),
                  secondary: const TomoIconTile(Icons.shuffle),
                  title: const Text('Shuffle new sessions'),
                  subtitle: const Text(
                    'Start supported decks in a randomized order',
                  ),
                  value: settings.shuffle,
                  onChanged: (enabled) => runUiAction(
                    context,
                    () => ref
                        .read(preferencesControllerProvider.notifier)
                        .setShuffle(enabled),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TomoSpacing.lg),
            const TomoSectionLabel('Display & aesthetics'),
            const SizedBox(height: TomoSpacing.sm),
            _SettingsGroup(
              children: [
                SwitchListTile(
                  key: const Key('theme-switch'),
                  secondary: const TomoIconTile(
                    Icons.dark_mode_outlined,
                    color: TomoColors.blue,
                  ),
                  title: const Text('Dark theme'),
                  subtitle: Text(
                    settings.themeMode == ThemeMode.dark
                        ? 'Atmospheric deep charcoal'
                        : 'Warm light appearance',
                  ),
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (enabled) => runUiAction(
                    context,
                    () => ref
                        .read(preferencesControllerProvider.notifier)
                        .setTheme(enabled ? ThemeMode.dark : ThemeMode.light),
                  ),
                ),
              ],
            ),
            const SizedBox(height: TomoSpacing.lg),
            const TomoSectionLabel('Data & offline storage'),
            const SizedBox(height: TomoSpacing.sm),
            _ContentStatus(level: settings.level),
            const SizedBox(height: TomoSpacing.lg),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.flutter_dash,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tomo v2.0.0',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    'Local-first Japanese study companion',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _LevelSelector extends ConsumerWidget {
  const _LevelSelector({required this.selected});

  final JlptLevel selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(levelCatalogProvider);
    return _SettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(TomoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.flag_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Target JLPT Level',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Text(
                    available.isLoading
                        ? 'Checking…'
                        : available.value?.contains(selected) == true
                        ? 'Installed'
                        : 'Unavailable',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(TomoRadii.control),
                ),
                child: Row(
                  children: JlptLevel.values.map((level) {
                    final installed = available.value?.contains(level) == true;
                    final active = level == selected;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: SizedBox(
                          height: 42,
                          child: active
                              ? FilledButton(
                                  onPressed: null,
                                  style: FilledButton.styleFrom(
                                    disabledBackgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    disabledForegroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(level.label),
                                )
                              : TextButton(
                                  onPressed: installed
                                      ? () => runUiAction(
                                          context,
                                          () => ref
                                              .read(
                                                preferencesControllerProvider
                                                    .notifier,
                                              )
                                              .selectLevel(level),
                                        )
                                      : null,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(level.label),
                                ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (available.hasError) ...[
                const SizedBox(height: 8),
                Text(
                  'Installed levels could not be checked.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ContentStatus extends ConsumerWidget {
  const _ContentStatus({required this.level});

  final JlptLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _SettingsGroup(
    children: [
      ref
          .watch(levelContentProvider(level))
          .when(
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Checking offline content'),
            ),
            error: (_, _) => ListTile(
              leading: TomoIconTile(
                Icons.cloud_off_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: const Text('Offline content unavailable'),
              subtitle: const Text(
                'Retry after checking the installed assets.',
              ),
              trailing: IconButton(
                tooltip: 'Retry',
                onPressed: () => ref.invalidate(levelContentProvider(level)),
                icon: const Icon(Icons.refresh),
              ),
            ),
            data: (snapshot) => ListTile(
              leading: const TomoIconTile(Icons.offline_pin_outlined),
              title: const Text('Offline content ready'),
              subtitle: Text(
                '${snapshot.content.vocabulary.length} ${level.label} words · ${_source(snapshot.source)} version ${snapshot.version}',
              ),
              trailing: TomoBadge(snapshot.source.name.toUpperCase()),
            ),
          ),
    ],
  );

  static String _source(ContentSource source) => switch (source) {
    ContentSource.bundled => 'bundled',
    ContentSource.cache => 'cached',
    ContentSource.remote => 'downloaded',
  };
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(TomoRadii.card),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    ),
  );
}
