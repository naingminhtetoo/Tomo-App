import 'package:flutter/services.dart';
import '../../../../core/constants/content_constants.dart';
import '../../../../core/storage/content_cache.dart';
import '../../../level_selection/domain/jlpt_level.dart';
import '../models/content_manifest.dart';

abstract interface class LocalVocabularyDataSource {
  Future<CachedContent?> readCache(JlptLevel level);
  Future<CachedContent?> readBundle(JlptLevel level);
  Future<void> writeCache(JlptLevel level, CachedContent content);
}

class AssetLocalVocabularyDataSource implements LocalVocabularyDataSource {
  const AssetLocalVocabularyDataSource({
    required this.cache,
    required this.bundle,
  });
  final ContentCache cache;
  final AssetBundle bundle;

  @override
  Future<CachedContent?> readCache(JlptLevel level) => cache.read(level.name);

  @override
  Future<CachedContent?> readBundle(JlptLevel level) async {
    final manifest = ContentManifest.decode(
      await bundle.loadString(ContentConstants.bundledManifest),
    );
    final version = manifest.versions[level];
    if (version == null) return null;
    return CachedContent(
      version: version,
      json: await bundle.loadString('assets/data/${level.name}.json'),
    );
  }

  @override
  Future<void> writeCache(JlptLevel level, CachedContent content) =>
      cache.write(level.name, content);
}
