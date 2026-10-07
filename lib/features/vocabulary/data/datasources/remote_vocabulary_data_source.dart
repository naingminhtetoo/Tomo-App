import '../../../../core/network/json_http_client.dart';
import '../../../level_selection/domain/jlpt_level.dart';
import '../models/content_manifest.dart';

abstract interface class RemoteVocabularyDataSource {
  Future<ContentManifest?> fetchManifest();
  Future<String> fetchLevel(JlptLevel level);
}

class HttpRemoteVocabularyDataSource implements RemoteVocabularyDataSource {
  const HttpRemoteVocabularyDataSource({required this.http, this.baseUri});
  final JsonHttpClient http;
  final Uri? baseUri;

  @override
  Future<ContentManifest?> fetchManifest() async {
    final uri = baseUri;
    if (uri == null) return null;
    return ContentManifest.decode(
      await http.get(uri.resolve('content-manifest.json')),
    );
  }

  @override
  Future<String> fetchLevel(JlptLevel level) {
    final uri = baseUri;
    if (uri == null) throw StateError('Remote content is not configured.');
    return http.get(uri.resolve('${level.name}.json'));
  }
}
