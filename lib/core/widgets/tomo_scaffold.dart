import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TomoScaffold extends StatelessWidget {
  const TomoScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showNavigation = true,
    this.brandHeader = false,
    this.levelLabel,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showNavigation, brandHeader;
  final String? levelLabel;
  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !brandHeader,
        toolbarHeight: brandHeader ? 88 : 72,
        title: brandHeader
            ? TomoBrand(levelLabel: levelLabel)
            : Text(title, overflow: TextOverflow.ellipsis),
        actions: actions,
      ),
      bottomNavigationBar: showNavigation
          ? NavigationBar(
              selectedIndex: path.startsWith('/review')
                  ? 2
                  : path == '/progress'
                  ? 3
                  : path.startsWith('/study') || path == '/levels'
                  ? 1
                  : 0,
              onDestinationSelected: (index) => context.go(
                [
                  '/home',
                  '/study/${levelLabel?.toLowerCase() ?? 'n2'}',
                  '/review',
                  '/progress',
                ][index],
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  label: 'Study',
                ),
                NavigationDestination(
                  icon: Icon(Icons.replay),
                  label: 'Review',
                ),
                NavigationDestination(
                  icon: Icon(Icons.trending_up),
                  label: 'Progress',
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class TomoBrand extends StatelessWidget {
  const TomoBrand({super.key, this.levelLabel});
  final String? levelLabel;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          Icons.auto_stories_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Tomo', style: Theme.of(context).textTheme.titleLarge),
                if (levelLabel != null) ...[
                  const SizedBox(width: 8),
                  TomoBadge(levelLabel!),
                ],
              ],
            ),
            Text(
              'Japanese Study Companion',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class TomoBadge extends StatelessWidget {
  const TomoBadge(this.label, {super.key, this.accent = true});
  final String label;
  final bool accent;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? scheme.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent ? scheme.primary : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    ),
  );
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = 24,
    this.accent = false,
  });
  final Widget child;
  final double padding;
  final bool accent;
  @override
  Widget build(BuildContext context) => Card(
    child: Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: accent
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Color.alphaBlend(
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.07),
                    Theme.of(context).colorScheme.surface,
                  ),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              )
            : null,
      ),
      child: child,
    ),
  );
}

class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.message,
  });
  final String title, message;
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
