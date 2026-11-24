import '../errors/content_exception.dart';

enum ContentLanguage {
  japanese('ja', 'Japanese', '日本語'),
  english('en', 'English', 'English'),
  burmese('my', 'Burmese', 'မြန်မာ');

  const ContentLanguage(this.code, this.label, this.nativeLabel);

  final String code;
  final String label;
  final String nativeLabel;

  static ContentLanguage? tryParse(String? value) =>
      values.where((language) => language.code == value).firstOrNull;
}

class LocalizedValue {
  const LocalizedValue({required this.language, required this.text});

  final ContentLanguage language;
  final String text;
}

/// Optional learning-content text for schema-v1 JSON.
///
/// Resolution is deterministic: selected language, then English, then
/// Japanese. The returned value retains its actual language so fallback text
/// can never be mislabeled in the UI.
class LocalizedText {
  const LocalizedText({this.japanese, this.english, this.burmese});

  final String? japanese;
  final String? english;
  final String? burmese;

  bool get isEmpty => japanese == null && english == null && burmese == null;
  bool get isNotEmpty => !isEmpty;

  String? value(ContentLanguage language) => switch (language) {
    ContentLanguage.japanese => japanese,
    ContentLanguage.english => english,
    ContentLanguage.burmese => burmese,
  };

  LocalizedValue? resolve(ContentLanguage selected) {
    final order = <ContentLanguage>[
      selected,
      ContentLanguage.english,
      ContentLanguage.japanese,
    ];
    for (final language in order.toSet()) {
      final text = value(language);
      if (text != null) return LocalizedValue(language: language, text: text);
    }
    return null;
  }

  LocalizedText withEnglishFallback(String? legacyEnglish) => LocalizedText(
    japanese: japanese,
    english: english ?? _clean(legacyEnglish),
    burmese: burmese,
  );

  factory LocalizedText.fromJson(Object? value) {
    if (value == null) return const LocalizedText();
    if (value is! Map<String, dynamic>) {
      throw const ContentException('Localized text must be a JSON object.');
    }
    String? read(String key) {
      final raw = value[key];
      if (raw == null) return null;
      if (raw is! String) {
        throw const ContentException('Localized text value must be text.');
      }
      return _clean(raw);
    }

    return LocalizedText(
      japanese: read(ContentLanguage.japanese.code),
      english: read(ContentLanguage.english.code),
      burmese: read(ContentLanguage.burmese.code),
    );
  }

  Map<String, String> toJson() => {
    ContentLanguage.japanese.code: ?japanese,
    ContentLanguage.english.code: ?english,
    ContentLanguage.burmese.code: ?burmese,
  };

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
