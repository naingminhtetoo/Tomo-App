import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tomo_theme.dart';

class TomoScaffold extends StatelessWidget {
  const TomoScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showNavigation = true,
    this.brandHeader = false,
    this.levelLabel,
    this.sectionLabel = 'Japanese Study Companion',
    this.maxContentWidth = 920,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showNavigation, brandHeader;
  final String? levelLabel;
  final String sectionLabel;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !brandHeader,
        toolbarHeight: 68,
        title: brandHeader
            ? TomoBrand(levelLabel: levelLabel, sectionLabel: sectionLabel)
            : Text(title, overflow: TextOverflow.ellipsis),
        actions: actions,
      ),
      bottomNavigationBar: showNavigation
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(TomoRadii.card),
              ),
              child: NavigationBar(
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
                    selectedIcon: Icon(Icons.menu_book),
                    label: 'Study',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.sync),
                    label: 'Review',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.trending_up),
                    label: 'Progress',
                  ),
                ],
              ),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              TomoSpacing.mobileMargin,
              TomoSpacing.sm,
              TomoSpacing.mobileMargin,
              TomoSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class TomoBrand extends StatelessWidget {
  const TomoBrand({
    super.key,
    this.levelLabel,
    this.sectionLabel = 'Japanese Study Companion',
  });

  final String? levelLabel;
  final String sectionLabel;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          '友',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text('Tomo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 5),
                Text(
                  '友',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (levelLabel != null) ...[
                  const SizedBox(width: 8),
                  Flexible(child: TomoBadge('JLPT $levelLabel')),
                ],
              ],
            ),
            Text(
              sectionLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class TomoBadge extends StatelessWidget {
  const TomoBadge(this.label, {super.key, this.accent = true, this.color});

  final String label;
  final bool accent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground =
        color ?? (accent ? scheme.primary : scheme.onSurfaceVariant);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent || color != null
            ? foreground.withValues(alpha: 0.14)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(TomoRadii.pill),
        border: Border.all(
          color: accent || color != null
              ? foreground.withValues(alpha: 0.18)
              : scheme.outlineVariant,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
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
    padding: const EdgeInsets.only(bottom: TomoSpacing.md),
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
    this.padding = TomoSpacing.lg,
    this.accent = false,
    this.color,
  });

  final Widget child;
  final double padding;
  final bool accent;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TomoRadii.card),
        gradient: accent
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Color.alphaBlend(
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
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
