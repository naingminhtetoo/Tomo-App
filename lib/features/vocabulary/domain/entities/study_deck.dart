import '../../../../core/utils/content_json.dart';
import '../../../level_selection/domain/jlpt_level.dart';

class StudyDeck {
  StudyDeck({
    required this.id,
    required this.title,
    required this.level,
    required this.category,
    required List<String> contentIds,
    this.source,
    this.chapter,
  }) : contentIds = List.unmodifiable(contentIds);
  final String id, title, category;
  final JlptLevel level;
  final String? source;
  final int? chapter;
  final List<String> contentIds;
  factory StudyDeck.fromJson(Map<String, dynamic> j) => StudyDeck(
    id: jsonText(j['id'], nonEmpty: true),
    title: jsonText(j['title']),
    category: jsonText(j['category'], nonEmpty: true),
    level:
        JlptLevel.tryParse(jsonText(j['level'])) ??
        (throw const FormatException('Invalid deck level')),
    source: j['source'] as String?,
    chapter: j['chapter'] as int?,
    contentIds: jsonTexts(j['contentIds']),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'level': level.label,
    'category': category,
    if (source != null) 'source': source,
    if (chapter != null) 'chapter': chapter,
    'contentIds': contentIds,
  };
}
