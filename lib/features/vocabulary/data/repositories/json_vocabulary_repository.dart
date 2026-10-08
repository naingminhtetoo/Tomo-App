import 'dart:convert';

import '../../../../core/errors/content_exception.dart';
import '../../../../core/storage/content_cache.dart';
import '../../../level_selection/domain/jlpt_level.dart';
import '../../domain/entities/level_content.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../datasources/local_vocabulary_data_source.dart';
import '../datasources/remote_vocabulary_data_source.dart';
import '../models/legacy_vocabulary_mapper.dart';

class JsonVocabularyRepository implements VocabularyRepository {
  JsonVocabularyRepository({
    required this.local,
    required this.remote,
    this.mapper = const LegacyVocabularyMapper(),
  });
  final LocalVocabularyDataSource local;
  final RemoteVocabularyDataSource remote;
  final LegacyVocabularyMapper mapper;
  Future<void> _updates = Future.value();

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
    // Serialize refreshes so a slow earlier request cannot overwrite newer data.
    final operation = _updates.then((_) => _update(level, currentVersion));
    _updates = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<ContentSnapshot?> _update(JlptLevel level, int currentVersion) async {
    final manifest = await remote.fetchManifest();
    final version = manifest?.versions[level];
    if (version == null) return null;
    ContentSnapshot? previous;
    try {
      previous = await loadLocal(level);
    } catch (_) {}
    final files = manifest!.files[level];
    final previousVersions = previous?.fileVersions ?? const <String, int>{};
    final effectiveVersion =
        previous != null && previous.version > currentVersion
        ? previous.version
        : currentVersion;
    CachedContent data;
    if (files == null || files.containsKey('legacy')) {
      if (version <= effectiveVersion) return null;
      final file = files?['legacy'];
      data = CachedContent(
        version: version,
        json: file == null
            ? await remote.fetchLevel(level)
            : await remote.fetchFile(file.path),
        fileVersions: file == null ? const {} : {'legacy': file.version},
      );
    } else {
      final changed = files.entries
          .where((e) => e.value.version > (previousVersions[e.key] ?? 0))
          .toList();
      if (changed.isEmpty) return null;
      final document =
          previous?.content.toJson() ??
          {
            'schemaVersion': 1,
            'level': level.label,
            'vocabulary': [],
            'decks': [],
            'kanji': [],
            'grammar': [],
          };
      final fileVersions = <String, int>{...previousVersions}..remove('legacy');
      for (final entry in changed) {
        final download = jsonDecode(await remote.fetchFile(entry.value.path));
        if (download is! Map<String, dynamic> ||
            download['schemaVersion'] != 1 ||
            JlptLevel.tryParse(download['level'] as String?) != level ||
            download[entry.key] is! List) {
          throw const ContentException('Invalid component content schema.');
        }
        document[entry.key] = download[entry.key];
        fileVersions[entry.key] = entry.value.version;
      }
      data = CachedContent(
        version: version > effectiveVersion ? version : effectiveVersion,
        json: jsonEncode(document),
        fileVersions: fileVersions,
      );
    }
    final snapshot = _snapshot(data, level, ContentSource.remote);
    if (previous != null) {
      final identities = {
        for (final c in previous.content.vocabulary.values)
          LegacyVocabularyMapper.legacyId(level, c.word, c.reading): c.id,
      };
      for (final c in snapshot.content.vocabulary.values) {
        final old =
            identities[LegacyVocabularyMapper.legacyId(
              level,
              c.word,
              c.reading,
            )];
        if (old != null && old != c.id) {
          throw const ContentException(
            'Update changes an existing stable content ID.',
          );
        }
      }
      if (previous.content.vocabulary.isNotEmpty &&
          snapshot.content.vocabulary.isEmpty) {
        throw const ContentException(
          'Update unexpectedly removes all vocabulary.',
        );
      }
    }
    try {
      await local.writeCache(level, data);
    } catch (_) {
      // Caller may study this validated snapshot, but durable cache is unchanged.
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
    fileVersions: Map.unmodifiable(data.fileVersions),
  );
}
