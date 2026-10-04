import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../domain/jlpt_level.dart';
import 'level_catalog_controller.dart';

class LevelSelectionScreen extends ConsumerWidget {
  const LevelSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'JLPT level',
    child: ref
        .watch(levelCatalogProvider)
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => ErrorStatus(
            message: 'Could not load available levels.',
            onRetry: () => ref.invalidate(levelCatalogProvider),
          ),
          data: (available) => Column(
            children: JlptLevel.values
                .map(
                  (level) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        title: Text(level.label),
                        subtitle: Text(
                          available.contains(level)
                              ? 'Available to study'
                              : 'Coming soon',
                        ),
                        enabled: available.contains(level),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: available.contains(level)
                            ? () async {
                                try {
                                  await ref.read(
                                    preferencesControllerProvider.future,
                                  );
                                  await ref
                                      .read(
                                        preferencesControllerProvider.notifier,
                                      )
                                      .selectLevel(level);
                                  if (context.mounted) {
                                    context.goNamed(
                                      AppRoutes.study,
                                      pathParameters: {'level': level.name},
                                    );
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not save your level. Please try again.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
  );
}
