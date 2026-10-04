enum DeckCategory {
  kanji('kanji', 'Kanji（総まとめ）'),
  kanjiMaster('kanji_master', 'Kanji（漢字マスター）'),
  vocabularyShinkanzen('vocab_shinkansen', 'Vocabulary（新完全マスター）'),
  vocabularySoumatome('vocab_soumatome', 'Vocabulary（総まとめ）'),
  adverb('adverbs', 'Adverbs'),
  other('other', 'Other words');

  const DeckCategory(this.contentKey, this.label);
  final String contentKey;
  final String label;
  bool get hasChapterSelection => this != adverb;

  static DeckCategory? tryParse(String? key) {
    for (final category in values) {
      if (category.contentKey == key) return category;
    }
    return null;
  }
}
