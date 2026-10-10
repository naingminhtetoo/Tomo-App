import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../level_selection/data/app_preferences.dart';
import '../../level_selection/domain/jlpt_level.dart';

final preferencesControllerProvider =
    AsyncNotifierProvider<PreferencesController, AppPreferences>(
      PreferencesController.new,
    );

class PreferencesController extends AsyncNotifier<AppPreferences> {
  @override
  Future<AppPreferences> build() =>
      ref.watch(preferencesRepositoryProvider).load();

  Future<void> selectLevel(JlptLevel level) async {
    final available = await ref
        .read(levelCatalogRepositoryProvider)
        .availableLevels();
    if (!available.contains(level)) {
      throw StateError('This level is not available yet.');
    }
    await _save(state.requireValue.copyWith(level: level));
  }

  Future<void> setTheme(ThemeMode mode) =>
      _save(state.requireValue.copyWith(themeMode: mode));
  Future<void> setShuffle(bool enabled) =>
      _save(state.requireValue.copyWith(shuffle: enabled));

  Future<void> rememberLearning(LastLearningActivity activity) {
    final current = state.requireValue;
    final saved = current.lastLearning;
    if (saved?.level == activity.level &&
        saved?.category == activity.category &&
        saved?.source == activity.source &&
        saved?.deckId == activity.deckId) {
      return Future.value();
    }
    return _save(current.copyWith(lastLearning: activity));
  }

  Future<void> _save(AppPreferences preferences) async {
    await ref.read(preferencesRepositoryProvider).save(preferences);
    if (ref.mounted) state = AsyncData(preferences);
  }
}
