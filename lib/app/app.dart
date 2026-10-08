import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/preferences_controller.dart';
import 'router/app_router.dart';
import 'theme/tomo_theme.dart';

class TomoApp extends ConsumerWidget {
  const TomoApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Tomo',
    debugShowCheckedModeBanner: false,
    theme: TomoTheme.light,
    darkTheme: TomoTheme.dark,
    themeMode:
        ref.watch(preferencesControllerProvider).asData?.value.themeMode ??
        ThemeMode.dark,
    routerConfig: ref.watch(appRouterProvider),
  );
}
