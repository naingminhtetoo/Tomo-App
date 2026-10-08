import '../errors/content_exception.dart';

Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const ContentException('Expected a JSON object.');
  }
  return value;
}

List<dynamic> jsonList(Object? value) {
  if (value is! List) throw const ContentException('Expected a JSON array.');
  return value;
}

String jsonText(Object? value, {bool nonEmpty = false}) {
  if (value is! String || (nonEmpty && value.trim().isEmpty)) {
    throw const ContentException('Invalid text field.');
  }
  return value;
}

List<String> jsonTexts(Object? value) =>
    value == null ? const [] : jsonList(value).map((v) => jsonText(v)).toList();
