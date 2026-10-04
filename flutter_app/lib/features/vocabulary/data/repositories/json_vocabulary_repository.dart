import '../../../../core/errors/content_exception.dart';
import '../../../../core/storage/content_cache.dart';
import '../../../level_selection/domain/jlpt_level.dart';
import '../../domain/entities/level_content.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../datasources/local_vocabulary_data_source.dart';
import '../datasources/remote_vocabulary_data_source.dart';
import '../models/legacy_vocabulary_mapper.dart';

class JsonVocabularyRepository implements VocabularyRepository {
  const JsonVocabularyRepository({
    required this.local,
    required this.remote,
    this.mapper = const LegacyVocabularyMapper(),
  });
  final LocalVocabularyDataSource local;
  final RemoteVocabularyDataSource remote;
  final LegacyVocabularyMapper mapper;

  @override
  Future<ContentSnapshot> loadLocal(JlptLevel level) async {
    ContentSnapshot? cached;
    try {
      final data = await local.readCache(level);
      if (data != null && data.version > 0) {
        cached = _snapshot(data, level, ContentSource.cache);
      }
    } catch (_) {
      cached =
          null; // A corrupt/unavailable cache must not prevent offline startup.
    }
    ContentSnapshot? bundled;
    try {
      final data = await local.readBundle(level);
      if (data != null && data.version > 0) {
        bundled = _snapshot(data, level, ContentSource.bundled);
      }
    } catch (_) {
      // A valid cache is still useful if bundled content cannot be read.
    }
    if (cached != null &&
        (bundled == null || cached.version >= bundled.version)) {
      return cached;
    }
    if (bundled != null) {
      return bundled;
    }
    throw ContentException('No local content is available for ${level.label}.');
  }

  @override
  Future<ContentSnapshot?> checkForUpdate(
    JlptLevel level, {
    required int currentVersion,
  }) async {
    final manifest = await remote.fetchManifest();
    final version = manifest?.versions[level];
    if (version == null || version <= currentVersion) return null;
    final data = CachedContent(
      version: version,
      json: await remote.fetchLevel(level),
    );
    final snapshot = _snapshot(data, level, ContentSource.remote);
    try {
      await local.writeCache(level, data);
    } catch (_) {
      // Valid downloaded content remains usable even when cache storage is unavailable.
    }
    return snapshot;
  }

  ContentSnapshot _snapshot(
    CachedContent data,
    JlptLevel level,
    ContentSource source,
  ) => ContentSnapshot(
    content: mapper.decode(data.json, expectedLevel: level),
    version: data.version,
    source: source,
  );
}
