import '../../../core/utils/content_json.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/domain/entities/content_example.dart';

class GrammarContent {
  GrammarContent({
    required this.id,
    required this.pattern,
    required this.level,
    this.reading,
    this.explanation,
    List<String> meanings = const [],
    List<String> formation = const [],
    List<String> tags = const [],
    List<ContentExample> examples = const [],
  }) : meanings = List.unmodifiable(meanings),
       formation = List.unmodifiable(formation),
       tags = List.unmodifiable(tags),
       examples = List.unmodifiable(examples);
  final String id, pattern;
  final String? reading, explanation;
  final JlptLevel level;
  final List<String> meanings, formation, tags;
  final List<ContentExample> examples;
  factory GrammarContent.fromJson(Map<String, dynamic> j) => GrammarContent(
    id: jsonText(j['id'], nonEmpty: true),
    pattern: jsonText(j['pattern'], nonEmpty: true),
    level:
        JlptLevel.tryParse(jsonText(j['level'])) ??
        (throw const FormatException('Invalid grammar level')),
    reading: j['reading'] as String?,
    explanation: j['explanation'] as String?,
    meanings: jsonTexts(j['meanings']),
    formation: jsonTexts(j['formation']),
    tags: jsonTexts(j['tags']),
    examples: (j['examples'] == null ? const [] : jsonList(j['examples']))
        .map((e) => ContentExample.fromJson(jsonObject(e)))
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'pattern': pattern,
    'level': level.label,
    if (reading != null) 'reading': reading,
    if (explanation != null) 'explanation': explanation,
    'meanings': meanings,
    'formation': formation,
    'tags': tags,
    'examples': examples.map((e) => e.toJson()).toList(),
  };
}
