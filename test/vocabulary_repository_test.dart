import 'package:flutter_test/flutter_test.dart';
import 'package:tomo/core/storage/content_cache.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/vocabulary/data/datasources/local_vocabulary_data_source.dart';
import 'package:tomo/features/vocabulary/data/datasources/remote_vocabulary_data_source.dart';
import 'package:tomo/features/vocabulary/data/models/content_manifest.dart';
import 'package:tomo/features/vocabulary/data/repositories/json_vocabulary_repository.dart';
import 'package:tomo/features/vocabulary/domain/entities/level_content.dart';

const validJson = '{"level":"N2","kanji":{"chapters":[]}}';

class FakeLocal implements LocalVocabularyDataSource {
  CachedContent? cached;
  CachedContent? bundled = const CachedContent(version: 1, json: validJson);
  bool failBundle = false;
  bool failWrite = false;
  int writes = 0;
  @override
  Future<CachedContent?> readCache(JlptLevel level) async => cached;
  @override
  Future<CachedContent?> readBundle(JlptLevel level) async {
    if (failBundle) throw StateError('bundle unavailable');
    return bundled;
  }

  @override
  Future<void> writeCache(JlptLevel level, CachedContent content) async {
    if (failWrite) throw StateError('disk full');
    cached = content;
    writes++;
  }
}

class FakeRemote implements RemoteVocabularyDataSource {
  int version = 1;
  int manifests = 0;
  int downloads = 0;
  String json = validJson;
  bool fail = false;
  @override
  Future<ContentManifest?> fetchManifest() async {
    manifests++;
    if (fail) throw StateError('offline');
    return ContentManifest({JlptLevel.n2: version});
  }

  @override
  Future<String> fetchLevel(JlptLevel level) async {
    downloads++;
    return json;
  }
}

void main() {
  late FakeLocal local;
  late FakeRemote remote;
  late JsonVocabularyRepository repository;
  setUp(() {
    local = FakeLocal();
    remote = FakeRemote();
    repository = JsonVocabularyRepository(local: local, remote: remote);
  });
  test(
    'first offline launch reads bundled content without any network request',
    () async {
      remote.fail = true;
      final snapshot = await repository.loadLocal(JlptLevel.n2);
      expect(snapshot.source, ContentSource.bundled);
      expect(remote.manifests, 0);
    },
  );
  test(
    'newer valid cache wins and old cache does not mask newer bundled data',
    () async {
      local.cached = const CachedContent(version: 2, json: validJson);
      expect(
        (await repository.loadLocal(JlptLevel.n2)).source,
        ContentSource.cache,
      );
      local.bundled = const CachedContent(version: 3, json: validJson);
      expect((await repository.loadLocal(JlptLevel.n2)).version, 3);
    },
  );
  test(
    'corrupted or wrong-level cache falls back to bundled content',
    () async {
      for (final json in ['invalid', '{"level":"N1"}']) {
        local.cached = CachedContent(version: 2, json: json);
        expect(
          (await repository.loadLocal(JlptLevel.n2)).source,
          ContentSource.bundled,
        );
      }
    },
  );
  test('valid cache remains usable when bundle cannot be read', () async {
    local.cached = const CachedContent(version: 2, json: validJson);
    local.failBundle = true;
    expect(
      (await repository.loadLocal(JlptLevel.n2)).source,
      ContentSource.cache,
    );
  });
  test('unavailable local content reports a recoverable error', () async {
    local.bundled = null;
    await expectLater(repository.loadLocal(JlptLevel.n2), throwsException);
  });
  test('equal or older remote version avoids content downloads', () async {
    expect(
      await repository.checkForUpdate(JlptLevel.n2, currentVersion: 1),
      isNull,
    );
    expect(
      await repository.checkForUpdate(JlptLevel.n2, currentVersion: 2),
      isNull,
    );
    expect(remote.downloads, 0);
    expect(local.writes, 0);
  });
  test('new remote version validates, caches and returns content', () async {
    remote.version = 2;
    final updated = await repository.checkForUpdate(
      JlptLevel.n2,
      currentVersion: 1,
    );
    expect(updated?.source, ContentSource.remote);
    expect(updated?.version, 2);
    expect(local.cached?.version, 2);
    expect(remote.downloads, 1);
  });
  test('invalid remote data never replaces a good cache', () async {
    local.cached = const CachedContent(version: 1, json: validJson);
    remote.version = 2;
    remote.json = '{"level":"N1"}';
    await expectLater(
      repository.checkForUpdate(JlptLevel.n2, currentVersion: 1),
      throwsException,
    );
    expect(local.cached?.version, 1);
    expect(local.writes, 0);
  });
  test(
    'cache write failure does not discard validated downloaded content',
    () async {
      remote.version = 2;
      local.failWrite = true;
      expect(
        (await repository.checkForUpdate(
          JlptLevel.n2,
          currentVersion: 1,
        ))?.version,
        2,
      );
    },
  );
}
