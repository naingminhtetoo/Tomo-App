import '../../../../core/utils/content_json.dart';

class ContentExample {
  const ContentExample({required this.sentence, this.translation});
  final String sentence;
  final String? translation;
  factory ContentExample.fromJson(Map<String, dynamic> json) => ContentExample(
    sentence: jsonText(json['sentence'], nonEmpty: true),
    translation: json['translation'] == null
        ? null
        : jsonText(json['translation']),
  );
  Map<String, dynamic> toJson() => {
    'sentence': sentence,
    if (translation != null) 'translation': translation,
  };
}
