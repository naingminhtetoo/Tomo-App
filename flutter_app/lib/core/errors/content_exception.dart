class ContentException implements Exception {
  const ContentException(this.message);
  final String message;
  @override
  String toString() => message;
}
