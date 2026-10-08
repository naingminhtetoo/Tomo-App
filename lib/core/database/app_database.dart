import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Drift owns SQLite connections, transactions and schema-version metadata.
/// Explicit SQL keeps this small schema readable without generated source files.
class AppDatabase extends GeneratedDatabase {
  AppDatabase(super.executor);
  factory AppDatabase.open() => AppDatabase(
    LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(directory.path, 'tomo.sqlite')),
      );
    }),
  );
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final sql in _schema) {
        await customStatement(sql);
      }
    },
    onUpgrade: (_, from, to) async {
      // Add explicit, incremental ALTER/data migrations before raising version.
      // Never recreate the database or silently discard valuable user history.
      throw StateError('No migration defined from schema $from to $to.');
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
  static const _schema = [
    '''CREATE TABLE study_progress (
      content_id TEXT NOT NULL, content_type TEXT NOT NULL CHECK(content_type IN ('vocabulary','kanji','grammar')),
      status TEXT NOT NULL DEFAULT 'new' CHECK(status IN ('new','learning','mastered')),
      mastery_level INTEGER NOT NULL DEFAULT 0 CHECK(mastery_level >= 0),
      correct_count INTEGER NOT NULL DEFAULT 0 CHECK(correct_count >= 0),
      incorrect_count INTEGER NOT NULL DEFAULT 0 CHECK(incorrect_count >= 0),
      favorite INTEGER NOT NULL DEFAULT 0 CHECK(favorite IN (0,1)),
      difficult INTEGER NOT NULL DEFAULT 0 CHECK(difficult IN (0,1)),
      first_learned_at INTEGER, last_reviewed_at INTEGER, next_review_at INTEGER,
      review_interval INTEGER NOT NULL DEFAULT 0 CHECK(review_interval >= 0),
      ease_factor REAL NOT NULL DEFAULT 2.5 CHECK(ease_factor > 0),
      updated_at INTEGER NOT NULL, sync_status TEXT NOT NULL DEFAULT 'pending',
      PRIMARY KEY(content_id,content_type))''',
    '''CREATE TABLE study_sessions (
      id TEXT PRIMARY KEY NOT NULL, deck_id TEXT NOT NULL, level TEXT NOT NULL,
      mode TEXT NOT NULL, started_at INTEGER NOT NULL, ended_at INTEGER,
      reviewed_count INTEGER NOT NULL DEFAULT 0, correct_count INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL, sync_status TEXT NOT NULL DEFAULT 'pending')''',
    '''CREATE TABLE review_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT, content_id TEXT NOT NULL, content_type TEXT NOT NULL,
      rating TEXT NOT NULL CHECK(rating IN ('again','hard','good','easy')),
      reviewed_at INTEGER NOT NULL, previous_interval INTEGER NOT NULL, new_interval INTEGER NOT NULL,
      response_time_ms INTEGER, session_id TEXT REFERENCES study_sessions(id),
      updated_at INTEGER NOT NULL, sync_status TEXT NOT NULL DEFAULT 'pending',
      FOREIGN KEY(content_id,content_type) REFERENCES study_progress(content_id,content_type))''',
    '''CREATE TABLE active_session (
      singleton INTEGER PRIMARY KEY CHECK(singleton = 1), session_id TEXT NOT NULL REFERENCES study_sessions(id),
      deck_id TEXT NOT NULL, level TEXT NOT NULL, current_index INTEGER NOT NULL CHECK(current_index >= 0),
      study_mode TEXT NOT NULL, shuffle_enabled INTEGER NOT NULL, content_ids TEXT NOT NULL,
      started_at INTEGER NOT NULL, updated_at INTEGER NOT NULL)''',
    'CREATE INDEX progress_due ON study_progress(next_review_at)',
    'CREATE INDEX history_reviewed ON review_history(reviewed_at)',
    'CREATE INDEX history_content ON review_history(content_id,content_type)',
  ];
}
