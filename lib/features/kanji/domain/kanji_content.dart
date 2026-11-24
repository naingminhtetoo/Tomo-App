import '../../../core/utils/content_json.dart';
import '../../../core/localization/content_language.dart';
import '../../level_selection/domain/jlpt_level.dart';
import '../../vocabulary/domain/entities/content_example.dart';

class KanjiContent {
  KanjiContent({
    required this.id,
    required this.character,
    required this.level,
    this.strokes,
    this.explanation = const LocalizedText(),
    List<String> meanings = const [],
    List<String> onyomi = const [],
    List<String> kunyomi = const [],
    List<ContentExample> examples = const [],
  }) : meanings = List.unmodifiable(meanings),
       onyomi = List.unmodifiable(onyomi),
       kunyomi = List.unmodifiable(kunyomi),
       examples = List.unmodifiable(examples);
  final String id, character;
  final JlptLevel level;
  final int? strokes;
  final LocalizedText explanation;
  final List<String> meanings, onyomi, kunyomi;
  final List<ContentExample> examples;
  factory KanjiContent.fromJson(Map<String, dynamic> j) => KanjiContent(
    id: jsonText(j['id'], nonEmpty: true),
    character: jsonText(j['character'], nonEmpty: true),
    level:
        JlptLevel.tryParse(jsonText(j['level'])) ??
        (throw const FormatException('Invalid kanji level')),
    strokes: j['strokes'] as int?,
    explanation: LocalizedText.fromJson(j['explanation']),
    meanings: jsonTexts(j['meanings']),
    onyomi: jsonTexts(j['onyomi']),
    kunyomi: jsonTexts(j['kunyomi']),
    examples: (j['examples'] == null ? const [] : jsonList(j['examples']))
        .map((e) => ContentExample.fromJson(jsonObject(e)))
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'character': character,
    'level': level.label,
    if (strokes != null) 'strokes': strokes,
    if (explanation.isNotEmpty) 'explanation': explanation.toJson(),
    'meanings': meanings,
    'onyomi': onyomi,
    'kunyomi': kunyomi,
    'examples': examples.map((example) => example.toJson()).toList(),
  };
}
