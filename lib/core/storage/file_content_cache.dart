import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'content_cache.dart';

class FileContentCache implements ContentCache {
  FileContentCache({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  int _sequence = 0;
  Future<File> _file(String key) async {
    if (!RegExp(r'^n[1-5]$').hasMatch(key)) {
      throw ArgumentError.value(key, 'levelKey');
    }
    final directory = await _directory();
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
    final versions = Map<String, int>.from(data['fileVersions'] ?? {});
    if (version < 1 || versions.values.any((v) => v < 1)) {
      throw const FormatException('Invalid cached version');
    }
    return CachedContent(
      version: version,
      json: data['json'] as String,
      fileVersions: Map.unmodifiable(versions),
    );
  }

  @override
  Future<void> write(String levelKey, CachedContent content) async {
    final file = await _file(levelKey);
    final temporary = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.${_sequence++}.tmp',
    );
    try {
      await temporary.writeAsString(
        jsonEncode({
          'version': content.version,
          'json': content.json,
          'fileVersions': content.fileVersions,
        }),
        flush: true,
      );
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
