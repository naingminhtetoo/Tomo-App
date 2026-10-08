import 'package:flutter/material.dart';

import '../../../core/storage/preferences_store.dart';
import '../domain/jlpt_level.dart';

class AppPreferences {
  const AppPreferences({
    this.level = JlptLevel.n2,
    this.themeMode = ThemeMode.dark,
    this.shuffle = false,
  });
  final JlptLevel level;
  final ThemeMode themeMode;
  final bool shuffle;
  AppPreferences copyWith({
    JlptLevel? level,
    ThemeMode? themeMode,
    bool? shuffle,
  }) => AppPreferences(
    level: level ?? this.level,
    themeMode: themeMode ?? this.themeMode,
    shuffle: shuffle ?? this.shuffle,
  );
}

class AppPreferencesRepository {
  const AppPreferencesRepository(this.store);
  final PreferencesStore store;
  Future<AppPreferences> load() async => AppPreferences(
    level:
        JlptLevel.tryParse(await store.read('selected_level')) ?? JlptLevel.n2,
    themeMode: await store.read('theme') == 'light'
        ? ThemeMode.light
        : ThemeMode.dark,
    shuffle: await store.read('shuffle') == 'true',
  );
  Future<void> save(AppPreferences preferences) async {
    await store.write('selected_level', preferences.level.name);
    await store.write('theme', preferences.themeMode.name);
    await store.write('shuffle', preferences.shuffle.toString());
  }
}
