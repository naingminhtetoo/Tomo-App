import 'dart:convert';

import '../../../../core/errors/content_exception.dart';
import '../../../../core/utils/content_json.dart';
import '../../../level_selection/domain/jlpt_level.dart';

class ContentFile {
  const ContentFile({required this.version, required this.path});
  final int version;
  final String path;
  factory ContentFile.fromJson(Map<String, dynamic> j) {
    final path = jsonText(j['path'], nonEmpty: true);
    final uri = Uri.parse(path);
    if (uri.hasScheme ||
        uri.hasAuthority ||
        path.startsWith('/') ||
        path.contains('\\') ||
        path
            .split('/')
            .any(
              (s) =>
                  Uri.decodeComponent(s) == '..' ||
                  Uri.decodeComponent(s).contains('/'),
            ) ||
        uri.pathSegments.any((s) => s == '..') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ContentException(
        'Content file path must stay under the configured base URL.',
      );
    }
    return ContentFile(version: _version(j['version']), path: path);
  }
}

class ContentManifest {
  ContentManifest(
    Map<JlptLevel, int> versions, {
    Map<JlptLevel, Map<String, ContentFile>> files = const {},
  }) : versions = Map.unmodifiable(versions),
       files = Map.unmodifiable(
         files.map(
           (k, v) => MapEntry(k, Map<String, ContentFile>.unmodifiable(v)),
         ),
       );
  final Map<JlptLevel, int> versions;
  final Map<JlptLevel, Map<String, ContentFile>> files;
  factory ContentManifest.decode(String source) {
    final root = jsonObject(jsonDecode(source));
    final versioned = root.containsKey('schemaVersion');
    if (versioned && root['schemaVersion'] != 1) {
      throw const ContentException('Unsupported manifest schema.');
    }
    final levels = versioned ? jsonObject(root['levels']) : root;
    final versions = <JlptLevel, int>{};
    final files = <JlptLevel, Map<String, ContentFile>>{};
    for (final entry in levels.entries) {
      final level = JlptLevel.tryParse(entry.key);
      if (level == null) continue;
      final data = jsonObject(entry.value);
      versions[level] = _version(data['version']);
      if (data['files'] != null) {
        files[level] = {
          for (final e in jsonObject(data['files']).entries)
            e.key: ContentFile.fromJson(jsonObject(e.value)),
        };
        if (files[level]!.keys.any(
          (k) => ![
            'legacy',
            'vocabulary',
            'kanji',
            'grammar',
            'decks',
          ].contains(k),
        )) {
          throw const ContentException('Unsupported content file type.');
        }
        if (files[level]!.containsKey('legacy') && files[level]!.length != 1) {
          throw const ContentException(
            'Legacy file cannot be mixed with component files.',
          );
        }
      }
    }
    return ContentManifest(versions, files: files);
  }
}

int _version(Object? v) {
  if (v is! int || v < 1) {
    throw const ContentException('Invalid content version.');
  }
  return v;
}
