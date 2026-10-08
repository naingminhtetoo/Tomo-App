import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TomoScaffold extends StatelessWidget {
  const TomoScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    bottomNavigationBar: NavigationBar(
      selectedIndex: switch (GoRouterState.of(context).uri.path) {
        '/review' => 2,
        '/progress' => 3,
        final path when path.startsWith('/study') || path == '/levels' => 1,
        _ => 0,
      },
      onDestinationSelected: (index) =>
          context.go(['/home', '/levels', '/review', '/progress'][index]),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.auto_stories_outlined),
          label: 'Study',
        ),
        NavigationDestination(icon: Icon(Icons.history), label: 'Review'),
        NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Progress'),
      ],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.message,
  });
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => TomoScaffold(
    title: title,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}
