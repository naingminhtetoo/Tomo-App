import '../../../level_selection/domain/jlpt_level.dart';
import '../entities/level_content.dart';

abstract interface class VocabularyRepository {
  /// Read validated cache, then bundled content. Never waits for the network.
  Future<ContentSnapshot> loadLocal(JlptLevel level);

  /// Optional version-gated refresh. Caller retains usable local data on failure.
  Future<ContentSnapshot?> checkForUpdate(JlptLevel level, {required int currentVersion});
}
