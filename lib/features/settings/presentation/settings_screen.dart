import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import 'preferences_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'Settings',
    child: ref
        .watch(preferencesControllerProvider)
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => ErrorStatus(
            message: 'Could not load preferences.',
            onRetry: () => ref.invalidate(preferencesControllerProvider),
          ),
          data: (preferences) => Card(
            child: SwitchListTile(
              title: const Text('Dark theme'),
              subtitle: const Text('Choose your preferred appearance'),
              value: preferences.themeMode == ThemeMode.dark,
              onChanged: (enabled) async {
                try {
                  await ref
                      .read(preferencesControllerProvider.notifier)
                      .setTheme(enabled ? ThemeMode.dark : ThemeMode.light);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not save your theme. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ),
  );
}
