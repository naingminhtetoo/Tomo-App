import '../../../level_selection/domain/jlpt_level.dart';
import '../entities/level_content.dart';
import '../entities/vocabulary_card.dart';

abstract interface class VocabularyRepository {
  /// Read validated cache, then bundled content. Never waits for the network.
  Future<ContentSnapshot> loadLocal(JlptLevel level);

  /// Optional version-gated refresh. Caller retains usable local data on failure.
  Future<ContentSnapshot?> checkForUpdate(
    JlptLevel level, {
    required int currentVersion,
  });
}

/// Word detail and search always resolve against the validated local master.
extension LocalVocabularyQueries on VocabularyRepository {
  Future<List<VocabularyCard>> searchLocal(
    JlptLevel level,
    String query,
  ) async => (await loadLocal(level)).content.search(query);
  Future<VocabularyCard?> findLocalById(JlptLevel level, String id) async =>
      (await loadLocal(level)).content.vocabulary[id];
}
