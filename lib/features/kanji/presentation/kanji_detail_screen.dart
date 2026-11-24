import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/tomo_theme.dart';
import '../../../core/localization/content_language.dart';
import '../../../core/widgets/async_status.dart';
import '../../../core/widgets/learning_detail_components.dart';
import '../../../core/widgets/tomo_scaffold.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../settings/presentation/preferences_controller.dart';
import '../../vocabulary/domain/entities/content_example.dart';
import '../../vocabulary/domain/entities/level_content.dart';
import '../../vocabulary/domain/entities/vocabulary_card.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import '../domain/kanji_content.dart';

class KanjiDetailScreen extends ConsumerWidget {
  const KanjiDetailScreen({super.key, required this.level, required this.id});

  final JlptLevel level;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TomoScaffold(
    title: 'Kanji Detail',
    showNavigation: false,
    maxContentWidth: 720,
    child: ref
        .watch(levelContentProvider(level))
        .when(
          loading: () => const LoadingStatus(),
          error: (_, _) => const Text('Kanji content could not be loaded.'),
          data: (snapshot) {
            final selectedLanguage =
                ref
                    .watch(preferencesControllerProvider)
                    .value
                    ?.explanationLanguage ??
                ContentLanguage.english;
            final item = snapshot.content.kanji
                .where((candidate) => candidate.id == id)
                .firstOrNull;
            return item == null
                ? const SurfacePanel(
                    child: Text('This kanji is not installed.'),
                  )
                : _KanjiDetail(
                    item: item,
                    content: snapshot.content,
                    selectedLanguage: selectedLanguage,
                  );
          },
        ),
  );
}

class _KanjiDetail extends StatelessWidget {
  const _KanjiDetail({
    required this.item,
    required this.content,
    required this.selectedLanguage,
  });

  final KanjiContent item;
  final LevelContent content;
  final ContentLanguage selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final related = content.vocabulary.values
        .where((word) => word.kanjiIds.contains(item.id))
        .toList();
    final examples = _examples(related, selectedLanguage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: TomoSpacing.sm,
          runSpacing: TomoSpacing.sm,
          alignment: WrapAlignment.spaceBetween,
          children: [
            const TomoBadge('KANJI'),
            TomoBadge('JLPT ${item.level.label}', accent: false),
          ],
        ),
        const SizedBox(height: TomoSpacing.md),
        SurfacePanel(
          accent: true,
          child: Column(
            children: [
              Text(
                item.character,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 84,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.meanings.isNotEmpty) ...[
                const SizedBox(height: TomoSpacing.sm),
                Text(
                  item.meanings.join(' · '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
              if (item.strokes != null) ...[
                const SizedBox(height: TomoSpacing.sm),
                TomoBadge('${item.strokes} strokes', accent: false),
              ],
            ],
          ),
        ),
        const SizedBox(height: TomoSpacing.lg),
        LearningDetailSection(
          title: 'Readings',
          icon: Icons.record_voice_over_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadingGroup(label: 'ON’YOMI 音読み', values: item.onyomi),
              const Divider(height: TomoSpacing.lg),
              _ReadingGroup(label: 'KUN’YOMI 訓読み', values: item.kunyomi),
            ],
          ),
        ),
        if (item.explanation.isNotEmpty) ...[
          const SizedBox(height: TomoSpacing.lg),
          LearningExplanationSection(
            explanation: item.explanation,
            selectedLanguage: selectedLanguage,
          ),
        ],
        if (examples.isNotEmpty) ...[
          const SizedBox(height: TomoSpacing.lg),
          LearningExampleSection(examples: examples),
        ],
        const SizedBox(height: TomoSpacing.lg),
        LearningDetailSection(
          title: 'Related Vocabulary',
          icon: Icons.menu_book_outlined,
          child: related.isEmpty
              ? Text(
                  'No related vocabulary is linked in this content file.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < related.length; index++) ...[
                      ListTile(
                        key: Key('related-word-${related[index].id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(related[index].word),
                        subtitle: Text(
                          '${related[index].reading} · ${related[index].meanings.join(' · ')}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.pushNamed(
                          AppRoutes.word,
                          pathParameters: {
                            'level': item.level.name,
                            'id': related[index].id,
                          },
                        ),
                      ),
                      if (index != related.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  List<LearningExampleData> _examples(
    List<VocabularyCard> words,
    ContentLanguage language,
  ) {
    final examples = <String, LearningExampleData>{};
    for (final example in item.examples) {
      final translation = example.translationFor(language);
      examples.putIfAbsent(
        example.sentence,
        () => LearningExampleData(
          sentence: example.sentence,
          translation: translation?.text,
          translationLanguage: translation?.language,
        ),
      );
    }
    for (final word in words) {
      for (final example in word.examples) {
        final translation = example.translationFor(language);
        examples.putIfAbsent(
          example.sentence,
          () => LearningExampleData(
            sentence: example.sentence,
            translation: translation?.text,
            translationLanguage: translation?.language,
          ),
        );
      }
      final sentence = word.exampleSentence;
      if (sentence != null && sentence.trim().isNotEmpty) {
        final translation = ContentExample(
          sentence: sentence,
          translation: word.exampleTranslation,
        ).translationFor(language);
        examples.putIfAbsent(
          sentence,
          () => LearningExampleData(
            sentence: sentence,
            translation: translation?.text,
            translationLanguage: translation?.language,
          ),
        );
      }
    }
    return examples.values.toList();
  }
}

class _ReadingGroup extends StatelessWidget {
  const _ReadingGroup({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: TomoSpacing.xs),
      Text(
        values.isEmpty ? 'Not included' : values.join(' · '),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: values.isEmpty
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
    ],
  );
}
