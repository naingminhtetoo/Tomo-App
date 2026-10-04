import 'dart:convert';
import '../../../../core/errors/content_exception.dart';
import '../../../level_selection/domain/jlpt_level.dart';

class ContentManifest {
  ContentManifest(Map<JlptLevel, int> versions) : versions = Map.unmodifiable(versions);
  final Map<JlptLevel, int> versions;

  factory ContentManifest.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) throw const ContentException('Invalid content manifest.');
    final versions = <JlptLevel, int>{};
    for (final entry in decoded.entries) {
      final level = JlptLevel.tryParse(entry.key);
      if (level == null) continue;
      final data = entry.value;
      if (data is! Map<String, dynamic> || data['version'] is! int || (data['version'] as int) < 1) {
        throw const ContentException('Invalid content version.');
      }
      versions[level] = data['version'] as int;
    }
    return ContentManifest(versions);
  }
}
