class CachedContent {
  const CachedContent({required this.version, required this.json});
  final int version;
  final String json;
}

/// Content cache only. Preferences and user review records use separate stores.
abstract interface class ContentCache {
  Future<CachedContent?> read(String levelKey);
  Future<void> write(String levelKey, CachedContent content);
}
