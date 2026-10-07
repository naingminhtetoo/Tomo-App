import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'content_cache.dart';

class FileContentCache implements ContentCache {
  Future<File> _file(String key) async {
    if (!RegExp(r'^n[1-5]$').hasMatch(key)) {
      throw ArgumentError.value(key, 'levelKey');
    }
    final directory = await getApplicationSupportDirectory();
    final cache = Directory('${directory.path}/tomo_content');
    await cache.create(recursive: true);
    return File('${cache.path}/$key.json');
  }

  @override
  Future<CachedContent?> read(String levelKey) async {
    final file = await _file(levelKey);
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final version = data['version'] as int;
    if (version < 1) throw const FormatException('Invalid cached version');
    return CachedContent(version: version, json: data['json'] as String);
  }

  @override
  Future<void> write(String levelKey, CachedContent content) async {
    final file = await _file(levelKey);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({'version': content.version, 'json': content.json}),
      flush: true,
    );
    await temporary.rename(file.path);
  }
}
