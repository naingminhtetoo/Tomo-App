import 'package:flutter/material.dart';

import '../../app/theme/tomo_theme.dart';
import '../localization/content_language.dart';
import 'tomo_scaffold.dart';

class LearningExampleData {
  const LearningExampleData({
    required this.sentence,
    this.translation,
    this.translationLanguage,
  });

  final String sentence;
  final String? translation;
  final ContentLanguage? translationLanguage;
}

class LearningDetailSection extends StatelessWidget {
  const LearningDetailSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: scheme.primary),
            const SizedBox(width: TomoSpacing.sm),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: TomoSpacing.sm),
        SurfacePanel(padding: TomoSpacing.md, child: child),
      ],
    );
  }
}

class LearningExampleSection extends StatelessWidget {
  const LearningExampleSection({super.key, required this.examples});

  final List<LearningExampleData> examples;

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) return const SizedBox.shrink();
    return LearningDetailSection(
      title: 'Example Sentences',
      icon: Icons.format_quote_outlined,
      child: Column(
        children: [
          for (var index = 0; index < examples.length; index++) ...[
            _ExampleTile(index: index, example: examples[index]),
            if (index != examples.length - 1)
              const SizedBox(height: TomoSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class LearningExplanationSection extends StatelessWidget {
  const LearningExplanationSection({
    super.key,
    required this.explanation,
    required this.selectedLanguage,
  });

  final LocalizedText explanation;
  final ContentLanguage selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final japanese = explanation.value(ContentLanguage.japanese);
    final resolved = explanation.resolve(selectedLanguage);
    final blocks = <LocalizedValue>[];
    if (japanese != null) {
      blocks.add(
        LocalizedValue(language: ContentLanguage.japanese, text: japanese),
      );
    }
    if (resolved != null &&
        !blocks.any(
          (value) =>
              value.language == resolved.language &&
              value.text == resolved.text,
        )) {
      blocks.add(resolved);
    }
    if (blocks.isEmpty) return const SizedBox.shrink();
    return LearningDetailSection(
      title: 'Explanation',
      icon: Icons.lightbulb_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < blocks.length; index++) ...[
            _LocalizedTextBlock(
              value: blocks[index],
              fallback:
                  blocks[index].language != selectedLanguage &&
                  blocks[index].language != ContentLanguage.japanese,
            ),
            if (index != blocks.length - 1)
              const Divider(height: TomoSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _LocalizedTextBlock extends StatelessWidget {
  const _LocalizedTextBlock({required this.value, required this.fallback});

  final LocalizedValue value;
  final bool fallback;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              '${value.language.label} explanation',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          if (fallback) const TomoBadge('FALLBACK', accent: false),
        ],
      ),
      const SizedBox(height: TomoSpacing.xs),
      Text(value.text, style: Theme.of(context).textTheme.bodyLarge),
    ],
  );
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({required this.index, required this.example});

  final int index;
  final LearningExampleData example;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(TomoRadii.control),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.sentence,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (example.translation?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  if (example.translationLanguage != null) ...[
                    Text(
                      '${example.translationLanguage!.label} translation',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    example.translation!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
