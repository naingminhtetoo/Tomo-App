import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants/content_constants.dart';
import '../core/network/json_http_client.dart';
import '../core/storage/file_content_cache.dart';
import '../core/storage/preferences_store.dart';
import '../features/level_selection/data/app_preferences.dart';
import '../features/level_selection/data/level_catalog_repository.dart';
import '../features/vocabulary/data/datasources/local_vocabulary_data_source.dart';
import '../features/vocabulary/data/datasources/remote_vocabulary_data_source.dart';
import '../features/vocabulary/data/repositories/json_vocabulary_repository.dart';
import '../features/vocabulary/domain/repositories/vocabulary_repository.dart';

final preferencesRepositoryProvider = Provider<AppPreferencesRepository>(
  (ref) => AppPreferencesRepository(SharedPreferencesStore()),
);
final levelCatalogRepositoryProvider = Provider<LevelCatalogRepository>(
  (ref) => LevelCatalogRepository(rootBundle),
);
final vocabularyRepositoryProvider = Provider<VocabularyRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  final base = ContentConstants.remoteBase;
  return JsonVocabularyRepository(
    local: AssetLocalVocabularyDataSource(
      cache: FileContentCache(),
      bundle: rootBundle,
    ),
    remote: HttpRemoteVocabularyDataSource(
      http: JsonHttpClient(client),
      baseUri: base.isEmpty
          ? null
          : Uri.parse(base.endsWith('/') ? base : '$base/'),
    ),
  );
});
