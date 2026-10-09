import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/tomo_theme.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_components.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../domain/jlpt_level.dart';
import 'level_catalog_controller.dart';

class LevelSelectionScreen extends ConsumerWidget {
  const LevelSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider);
    return TomoScaffold(
      title: 'JLPT level',
      levelLabel: preferences.value?.level.label,
      maxContentWidth: 640,
      child: ref
          .watch(levelCatalogProvider)
          .when(
            loading: () => const LoadingStatus(),
            error: (_, _) => ErrorStatus(
              message: 'Could not load available levels.',
              onRetry: () => ref.invalidate(levelCatalogProvider),
            ),
            data: (available) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TomoSectionLabel('Study target'),
                const SizedBox(height: TomoSpacing.sm),
                Text(
                  'Choose your JLPT level',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: TomoSpacing.sm),
                Text(
                  'Only levels with content installed on this device can be opened.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TomoSpacing.lg),
                ...JlptLevel.values.map(
                  (level) => Padding(
                    padding: const EdgeInsets.only(bottom: TomoSpacing.sm),
                    child: Card(
                      child: ListTile(
                        minTileHeight: 72,
                        leading: TomoIconTile(
                          available.contains(level)
                              ? Icons.school_outlined
                              : Icons.lock_outline,
                          color: available.contains(level)
                              ? null
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text('JLPT ${level.label}'),
                        subtitle: Text(
                          available.contains(level)
                              ? 'Available to study offline'
                              : 'Coming soon',
                        ),
                        enabled: available.contains(level),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: available.contains(level)
                            ? () => _select(context, ref, level)
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    JlptLevel level,
  ) async {
    try {
      await ref.read(preferencesControllerProvider.future);
      await ref.read(preferencesControllerProvider.notifier).selectLevel(level);
      if (context.mounted) {
        context.goNamed(AppRoutes.study, pathParameters: {'level': level.name});
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your level. Please try again.'),
          ),
        );
      }
    }
  }
}
