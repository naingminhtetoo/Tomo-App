import '../../../core/utils/content_json.dart';
import '../../level_selection/domain/jlpt_level.dart';

class KanjiContent {
  KanjiContent({
    required this.id,
    required this.character,
    required this.level,
    this.strokes,
    List<String> meanings = const [],
    List<String> onyomi = const [],
    List<String> kunyomi = const [],
  }) : meanings = List.unmodifiable(meanings),
       onyomi = List.unmodifiable(onyomi),
       kunyomi = List.unmodifiable(kunyomi);
  final String id, character;
  final JlptLevel level;
  final int? strokes;
  final List<String> meanings, onyomi, kunyomi;
  factory KanjiContent.fromJson(Map<String, dynamic> j) => KanjiContent(
    id: jsonText(j['id'], nonEmpty: true),
    character: jsonText(j['character'], nonEmpty: true),
    level:
        JlptLevel.tryParse(jsonText(j['level'])) ??
        (throw const FormatException('Invalid kanji level')),
    strokes: j['strokes'] as int?,
    meanings: jsonTexts(j['meanings']),
    onyomi: jsonTexts(j['onyomi']),
    kunyomi: jsonTexts(j['kunyomi']),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'character': character,
    'level': level.label,
    if (strokes != null) 'strokes': strokes,
    'meanings': meanings,
    'onyomi': onyomi,
    'kunyomi': kunyomi,
  };
}
