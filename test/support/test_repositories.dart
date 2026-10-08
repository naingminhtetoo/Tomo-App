import 'dart:io';
import 'package:tomo/core/storage/preferences_store.dart';
import 'package:tomo/features/level_selection/domain/jlpt_level.dart';
import 'package:tomo/features/vocabulary/data/models/legacy_vocabulary_mapper.dart';
import 'package:tomo/features/vocabulary/domain/entities/level_content.dart';
import 'package:tomo/features/vocabulary/domain/repositories/vocabulary_repository.dart';

class TestVocabularyRepository implements VocabularyRepository {
  @override
  Future<ContentSnapshot> loadLocal(JlptLevel level) async => ContentSnapshot(
    content: const LegacyVocabularyMapper().decode(
      File('assets/data/n2.json').readAsStringSync(),
      expectedLevel: level,
    ),
    version: 1,
    source: ContentSource.bundled,
  );
  @override
  Future<ContentSnapshot?> checkForUpdate(
    JlptLevel level, {
    required int currentVersion,
  }) async => null;
}

class MemoryPreferences implements PreferencesStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
