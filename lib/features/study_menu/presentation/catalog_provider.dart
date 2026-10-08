import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/presentation/vocabulary_controller.dart';
import '../../progress/domain/progress_repository.dart';
import '../../progress/presentation/progress_providers.dart';
import '../domain/study_catalog.dart';

final studyCatalogProvider = FutureProvider.family<StudyCatalog, JlptLevel>((
  ref,
  level,
) async {
  ref.watch(progressChangesProvider);
  final repository = ref.watch(progressRepositoryProvider);
  final content = (await ref.watch(levelContentProvider(level).future)).content;
  final catalog = StudyCatalog(content, const {}, const {});
  final categories = <StudyCategory, DeckProgress>{};
  final chapters = <String, DeckProgress>{};
  final sources = <String, DeckProgress>{};
  for (final category in StudyCategory.values) {
    final ids = catalog.ids(category);
    final summary = await repository.summary(contentIds: ids);
    categories[category] = DeckProgress(
      learned: summary.learned,
      total: ids.length,
    );
    for (final source in catalog.sources(category)) {
      final progress = await repository.summary(contentIds: source.contentIds);
      sources['${category.name}/${source.id}'] = DeckProgress(
        learned: progress.learned,
        total: source.contentIds.length,
      );
    }
  }
  for (final deck in content.decks) {
    final ids = deck.contentIds.toSet();
    chapters[deck.id] = DeckProgress(
      learned: (await repository.summary(contentIds: ids)).learned,
      total: ids.length,
    );
  }
  return StudyCatalog(
    content,
    Map.unmodifiable(categories),
    Map.unmodifiable(chapters),
    Map.unmodifiable(sources),
  );
});
final studyActivityProvider = FutureProvider.family<StudyActivity, JlptLevel>((
  ref,
  level,
) async {
  ref.watch(progressChangesProvider);
  final repository = ref.watch(progressRepositoryProvider);
  final content = (await ref.watch(levelContentProvider(level).future)).content;
  return repository.activity(
    contentIds: {
      ...content.vocabulary.keys,
      ...content.kanji.map((k) => k.id),
      ...content.grammar.map((g) => g.id),
    },
  );
});
