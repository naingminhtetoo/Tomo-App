import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tomo_theme.dart';
import '../../../core/localization/content_language.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/learning_detail_components.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import '../domain/grammar_content.dart';

class GrammarDetailScreen extends ConsumerWidget {
  const GrammarDetailScreen({super.key, required this.level, required this.id});

  final JlptLevel level;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'Grammar Detail',
    showNavigation: false,
    maxContentWidth: 720,
    child: ref
        .watch(levelContentProvider(level))
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => const Text('Grammar content could not be loaded.'),
          data: (snapshot) {
            final selectedLanguage =
                ref
                    .watch(preferencesControllerProvider)
                    .value
                    ?.explanationLanguage ??
                ContentLanguage.english;
            final item = snapshot.content.grammar
                .where((candidate) => candidate.id == id)
                .firstOrNull;
            return item == null
                ? const SurfacePanel(
                    child: Text('This grammar lesson is not installed.'),
                  )
                : _GrammarDetail(
                    item: item,
                    selectedLanguage: selectedLanguage,
                  );
          },
        ),
  );
}

class _GrammarDetail extends StatelessWidget {
  const _GrammarDetail({required this.item, required this.selectedLanguage});

  final GrammarContent item;
  final ContentLanguage selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final explanations = item.explanations.withEnglishFallback(
      item.explanation,
    );
    final examples = item.examples.map((example) {
      final translation = example.translationFor(selectedLanguage);
      return LearningExampleData(
        sentence: example.sentence,
        translation: translation?.text,
        translationLanguage: translation?.language,
      );
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: TomoSpacing.sm,
          runSpacing: TomoSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          children: [
            const TomoBadge('GRAMMAR'),
            TomoBadge('JLPT ${item.level.label}', accent: false),
          ],
        ),
        const SizedBox(height: TomoSpacing.md),
        SurfacePanel(
          accent: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.pattern,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              if (item.reading?.trim().isNotEmpty == true) ...[
                const SizedBox(height: TomoSpacing.sm),
                Text(
                  item.reading!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scheme.primary),
                ),
              ],
              if (item.meanings.isNotEmpty) ...[
                const SizedBox(height: TomoSpacing.md),
                Text(
                  item.meanings.join(' · '),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: TomoSpacing.md),
                Wrap(
                  spacing: TomoSpacing.sm,
                  runSpacing: TomoSpacing.sm,
                  children: item.tags
                      .map((tag) => TomoBadge(tag, accent: false))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        if (explanations.isNotEmpty) ...[
          const SizedBox(height: TomoSpacing.lg),
          LearningExplanationSection(
            explanation: explanations,
            selectedLanguage: selectedLanguage,
          ),
        ],
        if (item.formation.isNotEmpty) ...[
          const SizedBox(height: TomoSpacing.lg),
          LearningDetailSection(
            title: 'Formation & Usage',
            icon: Icons.account_tree_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: item.formation
                  .map(
                    (formation) => Padding(
                      padding: const EdgeInsets.only(bottom: TomoSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•', style: TextStyle(color: scheme.primary)),
                          const SizedBox(width: TomoSpacing.sm),
                          Expanded(child: Text(formation)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (examples.isNotEmpty) ...[
          const SizedBox(height: TomoSpacing.lg),
          LearningExampleSection(examples: examples),
        ],
      ],
    );
  }
}
