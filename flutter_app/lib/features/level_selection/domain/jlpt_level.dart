enum JlptLevel {
  n5,
  n4,
  n3,
  n2,
  n1;

  String get label => name.toUpperCase();
  static JlptLevel? tryParse(String? value) {
    for (final level in values) {
      if (level.name == value?.toLowerCase()) return level;
    }
    return null;
  }
}
