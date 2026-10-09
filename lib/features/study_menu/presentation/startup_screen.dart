import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../settings/presentation/preferences_controller.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesControllerProvider);
    if (preferences.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.goNamed(AppRoutes.home);
      });
    }
    return TomoScaffold(
      title: 'Tomo',
      showNavigation: false,
      child: preferences.when(
        data: (_) => const LoadingStatus(),
        loading: () => const LoadingStatus(),
        error: (_, _) => ErrorStatus(
          message: 'Could not load your preferences.',
          onRetry: () => ref.invalidate(preferencesControllerProvider),
        ),
      ),
    );
  }
}
