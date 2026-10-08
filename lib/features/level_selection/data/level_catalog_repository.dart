import 'package:flutter/services.dart';

import '../../../core/constants/content_constants.dart';
import '../../vocabulary/data/models/content_manifest.dart';
import '../domain/jlpt_level.dart';

class LevelCatalogRepository {
  const LevelCatalogRepository(this.bundle);
  final AssetBundle bundle;
  Future<Set<JlptLevel>> availableLevels() async => ContentManifest.decode(
    await bundle.loadString(ContentConstants.bundledManifest),
  ).versions.keys.toSet();
}
