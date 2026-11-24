import '../../../../core/utils/content_json.dart';
import '../../../../core/localization/content_language.dart';

class ContentExample {
  const ContentExample({
    required this.sentence,
    this.translation,
    this.translations = const LocalizedText(),
  });
  final String sentence;
  final String? translation;
  final LocalizedText translations;

  LocalizedValue? translationFor(ContentLanguage language) =>
      translations.withEnglishFallback(translation).resolve(language);

  factory ContentExample.fromJson(Map<String, dynamic> json) {
    final legacy = json['translation'] == null
        ? null
        : jsonText(json['translation']);
    return ContentExample(
      sentence: jsonText(json['sentence'], nonEmpty: true),
      translation: legacy,
      translations: LocalizedText.fromJson(json['translations']),
    );
  }
  Map<String, dynamic> toJson() => {
    'sentence': sentence,
    if (translation != null) 'translation': translation,
    if (translations.isNotEmpty) 'translations': translations.toJson(),
  };
}
