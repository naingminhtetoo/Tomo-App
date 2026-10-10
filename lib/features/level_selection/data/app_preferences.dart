import 'package:flutter/material.dart';

import '../../../core/storage/preferences_store.dart';
import '../domain/jlpt_level.dart';

class LastLearningActivity {
  const LastLearningActivity({
    required this.level,
    required this.category,
    required this.source,
    required this.deckId,
  });

  final JlptLevel level;
  final String category;
  final String source;
  final String deckId;
}

class AppPreferences {
  const AppPreferences({
    this.level = JlptLevel.n2,
    this.themeMode = ThemeMode.dark,
    this.shuffle = false,
    this.lastLearning,
  });
  final JlptLevel level;
  final ThemeMode themeMode;
  final bool shuffle;
  final LastLearningActivity? lastLearning;
  AppPreferences copyWith({
    JlptLevel? level,
    ThemeMode? themeMode,
    bool? shuffle,
    LastLearningActivity? lastLearning,
  }) => AppPreferences(
    level: level ?? this.level,
    themeMode: themeMode ?? this.themeMode,
    shuffle: shuffle ?? this.shuffle,
    lastLearning: lastLearning ?? this.lastLearning,
  );
}

class AppPreferencesRepository {
  const AppPreferencesRepository(this.store);
  final PreferencesStore store;
  Future<AppPreferences> load() async {
    final browseLevel = JlptLevel.tryParse(
      await store.read('last_learning_level'),
    );
    final category = await store.read('last_learning_category');
    final source = await store.read('last_learning_source');
    final deckId = await store.read('last_learning_deck');
    return AppPreferences(
      level:
          JlptLevel.tryParse(await store.read('selected_level')) ??
          JlptLevel.n2,
      themeMode: await store.read('theme') == 'light'
          ? ThemeMode.light
          : ThemeMode.dark,
      shuffle: await store.read('shuffle') == 'true',
      lastLearning:
          browseLevel != null &&
              category != null &&
              source != null &&
              deckId != null
          ? LastLearningActivity(
              level: browseLevel,
              category: category,
              source: source,
              deckId: deckId,
            )
          : null,
    );
  }

  Future<void> save(AppPreferences preferences) async {
    await store.write('selected_level', preferences.level.name);
    await store.write('theme', preferences.themeMode.name);
    await store.write('shuffle', preferences.shuffle.toString());
    final lastLearning = preferences.lastLearning;
    if (lastLearning != null) {
      await store.write('last_learning_level', lastLearning.level.name);
      await store.write('last_learning_category', lastLearning.category);
      await store.write('last_learning_source', lastLearning.source);
      await store.write('last_learning_deck', lastLearning.deckId);
    }
  }
}
